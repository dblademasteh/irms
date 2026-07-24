import dotenv from "dotenv";

dotenv.config();

function num(v: string | undefined, fallback: number): number {
  const n = v ? Number(v) : NaN;
  return Number.isFinite(n) ? n : fallback;
}

function str(v: string | undefined, fallback: string): string {
  return v && v.length ? v : fallback;
}

export const config = {
  port: num(process.env.PORT, 4000),
  corsOrigin: str(process.env.CORS_ORIGIN, "*"),
  dispatcherCode: str(process.env.DISPATCHER_CODE, "DISP-CODE"),
  jwt: {
    secret: str(process.env.JWT_SECRET, "dev_secret_change_me_in_prod"),
    accessTtl: num(process.env.JWT_ACCESS_TTL, 900),
    refreshTtl: num(process.env.JWT_REFRESH_TTL, 1209600),
  },
  pg: {
    host: str(process.env.PG_HOST, "localhost"),
    port: num(process.env.PG_PORT, 5432),
    database: str(process.env.PG_DATABASE, "irms"),
    user: str(process.env.PG_USER, "irms"),
    password: str(process.env.PG_PASSWORD, "irms_dev_password"),
  },
  redis: {
    host: str(process.env.REDIS_HOST, "localhost"),
    port: num(process.env.REDIS_PORT, 6379),
    password: str(process.env.REDIS_PASSWORD, ""),
  },
  s3: {
    bucket: str(process.env.S3_BUCKET, "irms-media"),
    region: str(process.env.S3_REGION, "us-east-1"),
    endpoint: str(process.env.S3_ENDPOINT, ""),
    accessKeyId: str(process.env.AWS_ACCESS_KEY_ID, "dev_access_key"),
    secretAccessKey: str(process.env.AWS_SECRET_ACCESS_KEY, "dev_secret_key"),
    maxBytes: num(process.env.MEDIA_MAX_BYTES, 10485760),
    backend: str(process.env.MEDIA_BACKEND, "local"),
  },
};
