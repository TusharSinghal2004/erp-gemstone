import {
  pgTable, serial, text, varchar, integer, numeric, boolean,
  timestamp, jsonb, pgEnum, uniqueIndex, index
} from "drizzle-orm/pg-core";

export const productStageEnum = pgEnum("product_stage", ["raw", "preform", "finished"]);
export const warehouseTypeEnum = pgEnum("warehouse_type", ["raw", "finished", "broker_approval", "quarantine"]);
export const lotStatusEnum = pgEnum("lot_status", ["draft", "received", "partial", "sold", "closed"]);
export const bunchStatusEnum = pgEnum("bunch_status", ["available", "reserved", "with_broker", "sold", "returned", "partial"]);
export const costBasisEnum = pgEnum("cost_basis", ["flat_per_carat", "per_bunch"]);
export const barcodeTypeEnum = pgEnum("barcode_type", ["master", "individual"]);
export const weightSourceEnum = pgEnum("weight_source", ["measured", "estimated"]);
export const ledgerDirectionEnum = pgEnum("ledger_direction", ["in", "out"]);

export const items = pgTable("items", {
  id: serial("id").primaryKey(),
  sku: varchar("sku", { length: 64 }).notNull().unique(),
  name: text("name").notNull(),
  productStage: productStageEnum("product_stage").notNull().default("finished"),
  hsnCode: varchar("hsn_code", { length: 16 }),
  defaultCaratPerStrand: numeric("default_carat_per_strand", { precision: 10, scale: 4 }),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const itemAttributes = pgTable("item_attributes", {
  id: serial("id").primaryKey(),
  itemId: integer("item_id").notNull().references(() => items.id, { onDelete: "cascade" }),
  key: varchar("key", { length: 64 }).notNull(),
  value: text("value").notNull(),
});

export const itemImages = pgTable("item_images", {
  id: serial("id").primaryKey(),
  itemId: integer("item_id").notNull().references(() => items.id, { onDelete: "cascade" }),
  storageKey: text("storage_key").notNull(),
  isPrimary: boolean("is_primary").notNull().default(false),
  sortOrder: integer("sort_order").notNull().default(0),
});

export const suppliers = pgTable("suppliers", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  email: varchar("email", { length: 255 }),
  phone: varchar("phone", { length: 32 }),
  address: text("address"),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const customers = pgTable("customers", {
  id: serial("id").primaryKey(),
  name: text("name").notNull(),
  email: varchar("email", { length: 255 }),
  phone: varchar("phone", { length: 32 }),
  address: text("address"),
  isBroker: boolean("is_broker").notNull().default(false),
  commissionPct: numeric("commission_pct", { precision: 5, scale: 2 }),
  isActive: boolean("is_active").notNull().default(true),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const warehouses = pgTable("warehouses", {
  id: serial("id").primaryKey(),
  name: text("name").notNull().unique(),
  type: warehouseTypeEnum("type").notNull(),
  isActive: boolean("is_active").notNull().default(true),
});

export const lots = pgTable("lots", {
  id: serial("id").primaryKey(),
  lotCode: varchar("lot_code", { length: 64 }).notNull().unique(),
  itemId: integer("item_id").notNull().references(() => items.id),
  supplierId: integer("supplier_id").references(() => suppliers.id),
  totalCarats: numeric("total_carats", { precision: 12, scale: 4 }).notNull(),
  totalStrands: integer("total_strands").notNull(),
  costBasis: costBasisEnum("cost_basis").notNull(),
  flatRatePerCarat: numeric("flat_rate_per_carat", { precision: 12, scale: 4 }),
  masterBarcode: varchar("master_barcode", { length: 64 }).notNull().unique(),
  status: lotStatusEnum("status").notNull().default("draft"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const bunches = pgTable("bunches", {
  id: serial("id").primaryKey(),
  bunchCode: varchar("bunch_code", { length: 64 }).notNull().unique(),
  lotId: integer("lot_id").notNull().references(() => lots.id),
  itemId: integer("item_id").notNull().references(() => items.id),
  actualCarats: numeric("actual_carats", { precision: 12, scale: 4 }),
  estimatedCarats: numeric("estimated_carats", { precision: 12, scale: 4 }),
  weightSource: weightSourceEnum("weight_source").notNull().default("estimated"),
  strandCount: integer("strand_count").notNull(),
  costPerCarat: numeric("cost_per_carat", { precision: 12, scale: 4 }),
  barcode: varchar("barcode", { length: 64 }).notNull().unique(),
  status: bunchStatusEnum("status").notNull().default("available"),
  remainingCarats: numeric("remaining_carats", { precision: 12, scale: 4 }).notNull(),
  remainingStrands: integer("remaining_strands").notNull(),
  warehouseId: integer("warehouse_id").references(() => warehouses.id),
  createdAt: timestamp("created_at").notNull().defaultNow(),
}, (t) => ({
  lotIdx: index("bunches_lot_idx").on(t.lotId),
  barcodeUniq: uniqueIndex("bunches_barcode_uniq").on(t.barcode),
}));

export const barcodes = pgTable("barcodes", {
  id: serial("id").primaryKey(),
  code: varchar("code", { length: 64 }).notNull().unique(),
  type: barcodeTypeEnum("type").notNull(),
  lotId: integer("lot_id").references(() => lots.id),
  bunchId: integer("bunch_id").references(() => bunches.id),
  isActive: boolean("is_active").notNull().default(true),
  printedAt: timestamp("printed_at"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export const barcodeEvents = pgTable("barcode_events", {
  id: serial("id").primaryKey(),
  barcodeCode: varchar("barcode_code", { length: 64 }).notNull(),
  eventType: varchar("event_type", { length: 64 }).notNull(),
  referenceType: varchar("reference_type", { length: 64 }),
  referenceId: integer("reference_id"),
  warehouseFromId: integer("warehouse_from_id"),
  warehouseToId: integer("warehouse_to_id"),
  userId: integer("user_id"),
  metadata: jsonb("metadata"),
  occurredAt: timestamp("occurred_at").notNull().defaultNow(),
});

export const stockLedger = pgTable("stock_ledger", {
  id: serial("id").primaryKey(),
  bunchId: integer("bunch_id").notNull().references(() => bunches.id),
  warehouseId: integer("warehouse_id").notNull().references(() => warehouses.id),
  qtyCarats: numeric("qty_carats", { precision: 12, scale: 4 }).notNull(),
  qtyStrands: integer("qty_strands").notNull(),
  direction: ledgerDirectionEnum("direction").notNull(),
  referenceType: varchar("reference_type", { length: 64 }),
  referenceId: integer("reference_id"),
  valuationRate: numeric("valuation_rate", { precision: 12, scale: 4 }),
  occurredAt: timestamp("occurred_at").notNull().defaultNow(),
}, (t) => ({
  bunchIdx: index("stock_ledger_bunch_idx").on(t.bunchId),
}));
