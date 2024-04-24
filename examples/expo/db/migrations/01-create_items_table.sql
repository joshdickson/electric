-- general functions

CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if the new row is different from the old row
    IF ROW(NEW.*) IS DISTINCT FROM ROW(OLD.*) THEN
        NEW.updated_at = NOW();
        RETURN NEW;
    ELSE
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;


-- tables

CREATE TABLE IF NOT EXISTS "brands" (
    id TEXT NOT NULL,
    name TEXT NOT NULL,
    mf_id TEXT NOT NULL,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    CONSTRAINT "brands_pkey" PRIMARY KEY ("id")
);

CREATE TRIGGER update_brands_modtime
BEFORE UPDATE ON brands
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();


CREATE TABLE IF NOT EXISTS "foods" (
    id TEXT NOT NULL,

    name TEXT NOT NULL,
    alternate_names TEXT, -- alternate names of the food
    -- tags VARCHAR(128)[] DEFAULT ARRAY[]::VARCHAR(128)[], -- todo, does not work with Electric
    
    type TEXT NOT NULL, -- whole, manufactured, branded
    category TEXT, -- the category of the food
    
    brand_id TEXT, -- the brand of the food
    ean_13 TEXT, -- the EAN-13 barcode of the food

    image_slug TEXT, -- the slug of the image
    image_source TEXT, -- the source of the image
    
    serving_quantity_common DOUBLE PRECISION NOT NULL,
    serving_unit_common TEXT NOT NULL,
    serving_quantity_metric DOUBLE PRECISION NOT NULL,
    serving_unit_metric TEXT NOT NULL,

    nutrition JSONB NOT NULL,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    FOREIGN KEY ("brand_id") REFERENCES "brands" ("id"),
    CONSTRAINT "foods_pkey" PRIMARY KEY ("id")
);

CREATE TRIGGER update_foods_modtime
BEFORE UPDATE ON foods
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();


CREATE TABLE IF NOT EXISTS "entries" (
    id TEXT NOT NULL,

    "user_id" TEXT NOT NULL,
    "food_id" TEXT, -- the associated food, if one is linked

    name TEXT NOT NULL, -- the human-readable name of the entry

    serving_quantity_common DOUBLE PRECISION NOT NULL,
    serving_unit_common TEXT NOT NULL,
    serving_quantity_metric DOUBLE PRECISION NOT NULL,
    serving_unit_metric TEXT NOT NULL,

    date TIMESTAMPTZ NOT NULL,

    nutrition JSONB NOT NULL,

    created_at TIMESTAMPTZ NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL,

    FOREIGN KEY ("food_id") REFERENCES "foods" ("id"),

    CONSTRAINT "entries_pkey" PRIMARY KEY ("id")
);

CREATE TRIGGER update_entries_modtime
BEFORE UPDATE ON entries
FOR EACH ROW
EXECUTE FUNCTION update_modified_column();

-- electrify tables

ALTER TABLE foods ENABLE ELECTRIC;
ALTER TABLE brands ENABLE ELECTRIC;
ALTER TABLE entries ENABLE ELECTRIC;
