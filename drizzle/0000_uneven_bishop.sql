CREATE TYPE "public"."barcode_type" AS ENUM('master', 'individual');--> statement-breakpoint
CREATE TYPE "public"."bunch_status" AS ENUM('available', 'reserved', 'with_broker', 'sold', 'returned', 'partial');--> statement-breakpoint
CREATE TYPE "public"."cost_basis" AS ENUM('flat_per_carat', 'per_bunch');--> statement-breakpoint
CREATE TYPE "public"."ledger_direction" AS ENUM('in', 'out');--> statement-breakpoint
CREATE TYPE "public"."lot_status" AS ENUM('draft', 'received', 'partial', 'sold', 'closed');--> statement-breakpoint
CREATE TYPE "public"."product_stage" AS ENUM('raw', 'preform', 'finished');--> statement-breakpoint
CREATE TYPE "public"."warehouse_type" AS ENUM('raw', 'finished', 'broker_approval', 'quarantine');--> statement-breakpoint
CREATE TYPE "public"."weight_source" AS ENUM('measured', 'estimated');--> statement-breakpoint
CREATE TABLE "barcode_events" (
	"id" serial PRIMARY KEY NOT NULL,
	"barcode_code" varchar(64) NOT NULL,
	"event_type" varchar(64) NOT NULL,
	"reference_type" varchar(64),
	"reference_id" integer,
	"warehouse_from_id" integer,
	"warehouse_to_id" integer,
	"user_id" integer,
	"metadata" jsonb,
	"occurred_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "barcodes" (
	"id" serial PRIMARY KEY NOT NULL,
	"code" varchar(64) NOT NULL,
	"type" "barcode_type" NOT NULL,
	"lot_id" integer,
	"bunch_id" integer,
	"is_active" boolean DEFAULT true NOT NULL,
	"printed_at" timestamp,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "barcodes_code_unique" UNIQUE("code")
);
--> statement-breakpoint
CREATE TABLE "bunches" (
	"id" serial PRIMARY KEY NOT NULL,
	"bunch_code" varchar(64) NOT NULL,
	"lot_id" integer NOT NULL,
	"item_id" integer NOT NULL,
	"actual_carats" numeric(12, 4),
	"estimated_carats" numeric(12, 4),
	"weight_source" "weight_source" DEFAULT 'estimated' NOT NULL,
	"strand_count" integer NOT NULL,
	"cost_per_carat" numeric(12, 4),
	"barcode" varchar(64) NOT NULL,
	"status" "bunch_status" DEFAULT 'available' NOT NULL,
	"remaining_carats" numeric(12, 4) NOT NULL,
	"remaining_strands" integer NOT NULL,
	"warehouse_id" integer,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "bunches_bunch_code_unique" UNIQUE("bunch_code"),
	CONSTRAINT "bunches_barcode_unique" UNIQUE("barcode")
);
--> statement-breakpoint
CREATE TABLE "customers" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"email" varchar(255),
	"phone" varchar(32),
	"address" text,
	"is_broker" boolean DEFAULT false NOT NULL,
	"commission_pct" numeric(5, 2),
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "item_attributes" (
	"id" serial PRIMARY KEY NOT NULL,
	"item_id" integer NOT NULL,
	"key" varchar(64) NOT NULL,
	"value" text NOT NULL
);
--> statement-breakpoint
CREATE TABLE "item_images" (
	"id" serial PRIMARY KEY NOT NULL,
	"item_id" integer NOT NULL,
	"storage_key" text NOT NULL,
	"is_primary" boolean DEFAULT false NOT NULL,
	"sort_order" integer DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "items" (
	"id" serial PRIMARY KEY NOT NULL,
	"sku" varchar(64) NOT NULL,
	"name" text NOT NULL,
	"product_stage" "product_stage" DEFAULT 'finished' NOT NULL,
	"hsn_code" varchar(16),
	"default_carat_per_strand" numeric(10, 4),
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	"updated_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "items_sku_unique" UNIQUE("sku")
);
--> statement-breakpoint
CREATE TABLE "lots" (
	"id" serial PRIMARY KEY NOT NULL,
	"lot_code" varchar(64) NOT NULL,
	"item_id" integer NOT NULL,
	"supplier_id" integer,
	"total_carats" numeric(12, 4) NOT NULL,
	"total_strands" integer NOT NULL,
	"cost_basis" "cost_basis" NOT NULL,
	"flat_rate_per_carat" numeric(12, 4),
	"master_barcode" varchar(64) NOT NULL,
	"status" "lot_status" DEFAULT 'draft' NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL,
	CONSTRAINT "lots_lot_code_unique" UNIQUE("lot_code"),
	CONSTRAINT "lots_master_barcode_unique" UNIQUE("master_barcode")
);
--> statement-breakpoint
CREATE TABLE "stock_ledger" (
	"id" serial PRIMARY KEY NOT NULL,
	"bunch_id" integer NOT NULL,
	"warehouse_id" integer NOT NULL,
	"qty_carats" numeric(12, 4) NOT NULL,
	"qty_strands" integer NOT NULL,
	"direction" "ledger_direction" NOT NULL,
	"reference_type" varchar(64),
	"reference_id" integer,
	"valuation_rate" numeric(12, 4),
	"occurred_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "suppliers" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"email" varchar(255),
	"phone" varchar(32),
	"address" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_at" timestamp DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "warehouses" (
	"id" serial PRIMARY KEY NOT NULL,
	"name" text NOT NULL,
	"type" "warehouse_type" NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	CONSTRAINT "warehouses_name_unique" UNIQUE("name")
);
--> statement-breakpoint
ALTER TABLE "barcodes" ADD CONSTRAINT "barcodes_lot_id_lots_id_fk" FOREIGN KEY ("lot_id") REFERENCES "public"."lots"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "barcodes" ADD CONSTRAINT "barcodes_bunch_id_bunches_id_fk" FOREIGN KEY ("bunch_id") REFERENCES "public"."bunches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bunches" ADD CONSTRAINT "bunches_lot_id_lots_id_fk" FOREIGN KEY ("lot_id") REFERENCES "public"."lots"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bunches" ADD CONSTRAINT "bunches_item_id_items_id_fk" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "bunches" ADD CONSTRAINT "bunches_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "item_attributes" ADD CONSTRAINT "item_attributes_item_id_items_id_fk" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "item_images" ADD CONSTRAINT "item_images_item_id_items_id_fk" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lots" ADD CONSTRAINT "lots_item_id_items_id_fk" FOREIGN KEY ("item_id") REFERENCES "public"."items"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "lots" ADD CONSTRAINT "lots_supplier_id_suppliers_id_fk" FOREIGN KEY ("supplier_id") REFERENCES "public"."suppliers"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "stock_ledger" ADD CONSTRAINT "stock_ledger_bunch_id_bunches_id_fk" FOREIGN KEY ("bunch_id") REFERENCES "public"."bunches"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "stock_ledger" ADD CONSTRAINT "stock_ledger_warehouse_id_warehouses_id_fk" FOREIGN KEY ("warehouse_id") REFERENCES "public"."warehouses"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "bunches_lot_idx" ON "bunches" USING btree ("lot_id");--> statement-breakpoint
CREATE UNIQUE INDEX "bunches_barcode_uniq" ON "bunches" USING btree ("barcode");--> statement-breakpoint
CREATE INDEX "stock_ledger_bunch_idx" ON "stock_ledger" USING btree ("bunch_id");