

DROP TABLE IF EXISTS public."Device";

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE IF NOT EXISTS public."Device"
(
    id UUID DEFAULT uuid_generate_v4(),
    "createdAt" timestamp(3) without time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" timestamp(3) without time zone NOT NULL,
    "deviceId" text COLLATE pg_catalog."default" NOT NULL,
    platform text COLLATE pg_catalog."default",
    "fcmToken" text COLLATE pg_catalog."default",
    locale text COLLATE pg_catalog."default",
    "buildNumber" integer,
    "userId" text COLLATE pg_catalog."default" NOT NULL,
    CONSTRAINT "Device_pkey" PRIMARY KEY (id),
    CONSTRAINT "Device_userId_fkey" FOREIGN KEY ("userId")
        REFERENCES public."User" (id) MATCH SIMPLE
        ON UPDATE CASCADE
        ON DELETE RESTRICT
)

