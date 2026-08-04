-- DEMO ONLY. Run only against an approved non-production database after
-- 20260804_management_demo_workflows. Synthetic catalogue; no real inventory or claims.

INSERT INTO products (uuid, product_code, product_name, brand, unit, mrp, selling_price, cost_price, margin_percentage, stock_quantity, is_demo_available, data_source, status)
SELECT * FROM (VALUES
('11111111-1111-4111-8111-111111111111'::uuid,'DEMO-VIT-001','Daily Balance Multivitamin','SHIELD Demo Wellness','30 capsules',499,449,300,33.18,40,true,'DEMO_SEED','DEMO'),
('22222222-2222-4222-8222-222222222222'::uuid,'DEMO-VIT-002','Sunshine Vitamin D3','SHIELD Demo Wellness','30 softgels',399,349,220,36.96,35,true,'DEMO_SEED','DEMO'),
('33333333-3333-4333-8333-333333333333'::uuid,'DEMO-NUT-001','Plant Protein Blend','SHIELD Demo Wellness','500 g',1099,999,650,34.93,24,true,'DEMO_SEED','DEMO'),
('44444444-4444-4444-8444-444444444444'::uuid,'DEMO-NUT-002','Everyday Nutrition Shake','SHIELD Demo Wellness','400 g',899,799,510,36.17,25,true,'DEMO_SEED','DEMO'),
('55555555-5555-4555-8555-555555555555'::uuid,'DEMO-DIA-001','Low Sugar Nutrition Mix','SHIELD Demo Wellness','400 g',749,699,450,35.62,20,true,'DEMO_SEED','DEMO'),
('66666666-6666-4666-8666-666666666666'::uuid,'DEMO-PER-001','Calm Evening Herbal Tea','SHIELD Demo Wellness','20 bags',299,269,160,40.52,45,true,'DEMO_SEED','DEMO'),
('77777777-7777-4777-8777-777777777777'::uuid,'DEMO-HER-001','Herbal Daily Capsules','SHIELD Demo Wellness','30 capsules',449,399,240,39.85,30,true,'DEMO_SEED','DEMO'),
('88888888-8888-4888-8888-888888888888'::uuid,'DEMO-DIG-001','Digestive Fibre Blend','SHIELD Demo Wellness','200 g',349,319,180,43.57,30,true,'DEMO_SEED','DEMO'),
('99999999-9999-4999-8999-999999999999'::uuid,'DEMO-DIG-002','Gentle Probiotic Sachets','SHIELD Demo Wellness','10 sachets',599,549,340,38.07,18,true,'DEMO_SEED','DEMO'),
('aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa'::uuid,'DEMO-JNT-001','Joint Mobility Support','SHIELD Demo Wellness','30 tablets',649,599,380,36.56,22,true,'DEMO_SEED','DEMO'),
('bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb'::uuid,'DEMO-JNT-002','Bone Care Mineral Blend','SHIELD Demo Wellness','30 tablets',549,499,310,37.88,22,true,'DEMO_SEED','DEMO'),
('cccccccc-cccc-4ccc-8ccc-cccccccccccc'::uuid,'DEMO-SKN-001','Hydrating Wellness Lotion','SHIELD Demo Wellness','100 ml',429,389,230,40.87,28,true,'DEMO_SEED','DEMO'),
('dddddddd-dddd-4ddd-8ddd-dddddddddddd'::uuid,'DEMO-HAR-001','Daily Hair Nutrition Blend','SHIELD Demo Wellness','30 capsules',579,529,330,37.62,26,true,'DEMO_SEED','DEMO'),
('eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee'::uuid,'DEMO-WEL-001','Refresh Electrolyte Mix','SHIELD Demo Wellness','10 sachets',299,279,150,46.24,36,true,'DEMO_SEED','DEMO')
) AS demo(uuid,product_code,product_name,brand,unit,mrp,selling_price,cost_price,margin_percentage,stock_quantity,is_demo_available,data_source,status)
WHERE NOT EXISTS (SELECT 1 FROM products existing WHERE existing.product_code = demo.product_code);
