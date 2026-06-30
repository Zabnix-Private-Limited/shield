import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { randomUUID } from 'crypto';
import { RBAC_ROLES } from '../src/auth/rbac-catalog';
import { ensureRbacCatalog } from '../src/auth/rbac-seed';
import { seedCommercialDefaults } from '../src/pricing/commercial-seed';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Seeding SHIELD database...');

  // 1. Seed RBAC and commercial baseline
  await ensureRbacCatalog(prisma);
  await seedCommercialDefaults(prisma);

  const roles: Record<string, any> = {};
  for (const roleInfo of RBAC_ROLES) {
    const role = await prisma.role.findUnique({
      where: { code: roleInfo.code },
    });
    if (role) {
      roles[roleInfo.code] = role;
    }
  }

  // 2. Seed Businesses
  const businessesData = [
    { code: 'SHG', name: 'Sahakar Healthcare Group', type: 'HEALTHCARE_PROVIDER' },
    { code: 'HYP-PERINTHALMANNA', name: 'SHIELD Hyper Pharmacy Perinthalmanna', type: 'PHARMACY' },
    { code: 'HYP-MANJERI', name: 'SHIELD Hyper Pharmacy Manjeri', type: 'PHARMACY' },
  ];

  const businesses: Record<string, any> = {};
  for (const bizInfo of businessesData) {
    let biz = await prisma.business.findUnique({
      where: { code: bizInfo.code },
    });

    if (!biz) {
      biz = await prisma.business.create({
        data: {
          uuid: randomUUID(),
          code: bizInfo.code,
          name: bizInfo.name,
          businessType: bizInfo.type,
          status: 'ACTIVE',
        },
      });
      console.log(`Created business: ${bizInfo.code}`);
    }
    businesses[bizInfo.code] = biz;
  }
  const business = businesses['SHG'];

  // 3. Seed Departments
  const departmentsData = [
    { code: 'ADMIN', name: 'Administration' },
    { code: 'PHARMACY', name: 'Pharmacy' },
    { code: 'CLINIC', name: 'Clinical Clinic' },
    { code: 'DENTAL', name: 'Dental Care' },
    { code: 'CRM', name: 'Customer Engagement' },
  ];

  const departments: Record<string, any> = {};
  for (const deptInfo of departmentsData) {
    let dept = await prisma.department.findFirst({
      where: { code: deptInfo.code, businessId: business.id },
    });

    if (!dept) {
      dept = await prisma.department.create({
        data: {
          uuid: randomUUID(),
          businessId: business.id,
          code: deptInfo.code,
          name: deptInfo.name,
          status: 'ACTIVE',
        },
      });
      console.log(`Created department: ${deptInfo.code}`);
    }
    departments[deptInfo.code] = dept;
  }

  // 4. Seed Membership Types
  const membershipTypesData = [
    { code: 'FOUNDING', name: 'Founding Member', discount: 15.00, fee: 0.00, creditEligible: true },
    { code: 'STANDARD', name: 'Standard Member', discount: 10.00, fee: 500.00, creditEligible: false },
  ];

  const membershipTypes: Record<string, any> = {};
  for (const typeInfo of membershipTypesData) {
    let memType = await prisma.membershipType.findUnique({
      where: { code: typeInfo.code },
    });

    if (!memType) {
      memType = await prisma.membershipType.create({
        data: {
          uuid: randomUUID(),
          code: typeInfo.code,
          name: typeInfo.name,
          joiningFee: typeInfo.fee,
          discountPercentage: typeInfo.discount,
          creditEligible: typeInfo.creditEligible,
          status: 'ACTIVE',
        },
      });
      console.log(`Created membership type: ${typeInfo.code}`);
    }
    membershipTypes[typeInfo.code] = memType;
  }

  // 5. Seed Staff Users
  const staffData = [
    { email: 'Zabnixprivatelimited@gmail.com', mobile: '9000000001', roleCode: 'ADMIN', deptCode: 'ADMIN', first: 'Zabnix', last: 'Admin', branchBizCode: 'SHG' },
    { email: 'softwareengineerzabnix@gmail.com', mobile: '9000000002', roleCode: 'SHIELD_AGENT', deptCode: 'ADMIN', first: 'Arjun', last: 'Menon', branchBizCode: 'SHG' },
    { email: 'platformcatalystzabnix@gmail.com', mobile: '9000000003', roleCode: 'CRM_EXECUTIVE', deptCode: 'CRM', first: 'Naila', last: 'Thomas', branchBizCode: 'SHG' },
    { email: 'juniordeveloperzabnix@gmail.com', mobile: '9000000004', roleCode: 'PHARMACY_PROVIDER', deptCode: 'PHARMACY', first: 'Rafi', last: 'Hassan', branchBizCode: 'HYP-PERINTHALMANNA' },
    { email: 'juniordeveloper02zabnix@gmail.com', mobile: '9000000005', roleCode: 'DOCTOR', deptCode: 'CLINIC', first: 'Devika', last: 'Nair', branchBizCode: 'SHG' },
    { email: 'juniordeveloper03zabnix@gmail.com', mobile: '9000000006', roleCode: 'DENTAL_PROVIDER', deptCode: 'DENTAL', first: 'Ishan', last: 'Roy', branchBizCode: 'SHG' },
  ];
  const retiredSeedEmails = [
    'admin@shield.com',
    'manager@shield.com',
    'executive@shield.com',
    'crm@shield.com',
    'pharmacy@shield.com',
    'clinic@shield.com',
    'dental@shield.com',
  ];

  await prisma.user.updateMany({
    where: {
      email: {
        in: retiredSeedEmails,
      },
      deletedAt: null,
    },
    data: {
      status: 'INACTIVE',
      deletedAt: new Date(),
      firebaseUid: null,
      authProvider: null,
    },
  });

  const staffUsers: Record<string, any> = {};
  for (const staffInfo of staffData) {
    let user = await prisma.user.findFirst({
      where: {
        OR: [{ mobile: staffInfo.mobile }, { email: staffInfo.email }],
      },
    });

    if (!user) {
      user = await prisma.user.create({
        data: {
          uuid: randomUUID(),
          employeeCode: `EMP-${staffInfo.mobile.slice(-4)}`,
          firstName: staffInfo.first,
          lastName: staffInfo.last,
          mobile: staffInfo.mobile,
          email: staffInfo.email,
          passwordHash: 'Zabnix@2025',
          roleId: roles[staffInfo.roleCode].id,
          departmentId: departments[staffInfo.deptCode].id,
          branchBusinessId: businesses[staffInfo.branchBizCode].id,
          status: 'ACTIVE',
        },
      });
      console.log(`Created staff user: ${staffInfo.email} (${staffInfo.roleCode})`);
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          employeeCode: `EMP-${staffInfo.mobile.slice(-4)}`,
          firstName: staffInfo.first,
          lastName: staffInfo.last,
          mobile: staffInfo.mobile,
          email: staffInfo.email,
          passwordHash: 'Zabnix@2025',
          roleId: roles[staffInfo.roleCode].id,
          departmentId: departments[staffInfo.deptCode].id,
          branchBusinessId: businesses[staffInfo.branchBizCode].id,
          status: 'ACTIVE',
          deletedAt: null,
          firebaseUid: null,
          authProvider: null,
        },
      });
      console.log(
        `Updated staff user: ${staffInfo.email} (${staffInfo.roleCode})`,
      );
    }
    staffUsers[staffInfo.roleCode] = user;
  }

  // 6. Seed Service Providers
  const providersData = [
    { code: 'clinic-1', name: 'Smart Clinic Manjeri', type: 'CLINIC', bizCode: 'SHG' },
    { code: 'clinic-2', name: 'Home Care Alanallur', type: 'HOME_VISIT', bizCode: 'SHG' },
    { code: 'dental-1', name: 'Dentistry Melattur', type: 'DENTAL', bizCode: 'SHG' },
    { code: 'lab-1', name: 'Laboratory Tirur', type: 'LABORATORY', bizCode: 'SHG' },
    { code: 'pharmacy-1', name: 'SHIELD Hyper Pharmacy Perinthalmanna', type: 'PHARMACY', bizCode: 'HYP-PERINTHALMANNA' },
    { code: 'pharmacy-2', name: 'SHIELD Hyper Pharmacy Manjeri', type: 'PHARMACY', bizCode: 'HYP-MANJERI' },
  ];

  const providers: Record<string, any> = {};
  for (const provInfo of providersData) {
    const targetBizId = businesses[provInfo.bizCode].id;
    let provider = await prisma.serviceProvider.findFirst({
      where: { providerName: provInfo.name, businessId: targetBizId },
    });

    if (!provider) {
      provider = await prisma.serviceProvider.create({
        data: {
          uuid: randomUUID(),
          businessId: targetBizId,
          providerName: provInfo.name,
          providerType: provInfo.type,
          status: 'ACTIVE',
        },
      });
      console.log(`Created provider: ${provInfo.name}`);
    }
    providers[provInfo.code] = provider;
  }

  // 7. Seed Product Categories and Products for customer purchase history
  const productCategoriesData = [
    { name: 'Medicines' },
    { name: 'Diagnostics' },
    { name: 'Dental Care' },
    { name: 'Wellness' },
  ];

  const productCategories: Record<string, any> = {};
  for (const categoryInfo of productCategoriesData) {
    let category = await prisma.productCategory.findFirst({
      where: { name: categoryInfo.name },
    });
    if (!category) {
      category = await prisma.productCategory.create({
        data: { name: categoryInfo.name },
      });
      console.log(`Created product category: ${categoryInfo.name}`);
    }
    productCategories[categoryInfo.name] = category;
  }

  const productsData = [
    { code: 'PARA650', name: 'Paracetamol 650mg', brand: 'Shield Care', unit: 'Strip', category: 'Medicines' },
    { code: 'MET500', name: 'Metformin 500mg', brand: 'Shield Care', unit: 'Strip', category: 'Medicines' },
    { code: 'CBC-PANEL', name: 'CBC Test Panel', brand: 'SHIELD Lab', unit: 'Test', category: 'Diagnostics' },
    { code: 'DENT-CLEAN', name: 'Dental Scaling Package', brand: 'SHIELD Dental', unit: 'Session', category: 'Dental Care' },
    { code: 'OMEGA3', name: 'Omega 3 Capsules', brand: 'Wellness Plus', unit: 'Bottle', category: 'Wellness' },
  ];

  const products: Record<string, any> = {};
  for (const productInfo of productsData) {
    let product = await prisma.product.findFirst({
      where: { productCode: productInfo.code },
    });
    if (!product) {
      product = await prisma.product.create({
        data: {
          uuid: randomUUID(),
          productCode: productInfo.code,
          productName: productInfo.name,
          brand: productInfo.brand,
          categoryId: productCategories[productInfo.category].id,
          unit: productInfo.unit,
        },
      });
      console.log(`Created product: ${productInfo.name}`);
    }
    products[productInfo.code] = product;
  }

  console.log('Database seeding finished successfully!');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
