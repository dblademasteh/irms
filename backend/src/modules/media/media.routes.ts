import Fastify, { FastifyInstance } from "fastify";
import { z } from "zod";
import { randomUUID } from "crypto";
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { config } from "../common/config.js";
import { authGuard } from "../common/auth-guard.js";
import { errors } from "../common/errors.js";
import * as repo from "./media.repo.js";

const presignSchema = z.object({
  type: z.enum(["photo", "video", "audio"]).default("photo"),
  contentType: z.string().max(200).optional(),
});

export async function registerMediaRoutes(app: FastifyInstance) {
  app.post(
    "/media/presign",
    { preHandler: authGuard(["reporter", "dispatcher", "admin"]) },
    async (req, reply) => {
      const body = presignSchema.parse(req.body);
      const key = `${randomUUID()}.${body.type === "photo" ? "jpg" : body.type}`;

      if (config.s3.backend === "s3") {
        const client = new S3Client({
          region: config.s3.region,
          endpoint: config.s3.endpoint || undefined,
          credentials: {
            accessKeyId: config.s3.accessKeyId,
            secretAccessKey: config.s3.secretAccessKey,
          },
        });
        const url = await getSignedUrl(
          client,
          new PutObjectCommand({ Bucket: config.s3.bucket, Key: key }),
          { expiresIn: 300 }
        );
        const media = await repo.createPending({
          type: body.type,
          url: `s3://${config.s3.bucket}/${key}`,
        });
        return reply.send({ uploadUrl: url, key, mediaId: media.id });
      }

      const media = await repo.createPending({
        type: body.type,
        url: `/public/uploads/${key}`,
      });
      return reply.send({
        uploadUrl: `/public/uploads/${key}`,
        key,
        mediaId: media.id,
        dev: true,
      });
    }
  );

  app.post(
    "/media/upload",
    async (req, reply) => {
      const data = await req.file();
      if (!data) throw errors.badRequest("No file uploaded");

      const buffer = await data.toBuffer();
      const ext = data.filename?.split(".").pop() ?? "jpg";
      const key = `${randomUUID()}.${ext}`;

      let url: string;

      if (config.s3.backend === "s3") {
        const client = new S3Client({
          region: config.s3.region,
          endpoint: config.s3.endpoint || undefined,
          credentials: {
            accessKeyId: config.s3.accessKeyId,
            secretAccessKey: config.s3.secretAccessKey,
          },
        });
        await client.send(
          new PutObjectCommand({
            Bucket: config.s3.bucket,
            Key: key,
            Body: buffer,
            ContentType: data.mimetype,
          })
        );
        url = `s3://${config.s3.bucket}/${key}`;
      } else {
        url = await repo.saveFileLocally(buffer, key);
      }

      const media = await repo.createPending({ type: "photo", url });
      return reply.send({ path: url, mediaId: media.id });
    }
  );

  app.post(
    "/media/confirm",
    { preHandler: authGuard(["reporter", "dispatcher", "admin"]) },
    async (req, reply) => {
      const body = z.object({ mediaId: z.string().uuid() }).parse(req.body);
      await repo.confirm(body.mediaId);
      return reply.send({ ok: true });
    }
  );
}