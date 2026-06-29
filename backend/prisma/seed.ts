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
    { email: 'admin@shield.com', mobile: '9000000001', roleCode: 'ADMIN', deptCode: 'ADMIN', first: 'Super', last: 'Admin' },
    { email: 'manager@shield.com', mobile: '9000000002', roleCode: 'ADMIN', deptCode: 'ADMIN', first: 'Branch', last: 'Manager' },
    { email: 'executive@shield.com', mobile: '9000000003', roleCode: 'SHIELD_AGENT', deptCode: 'ADMIN', first: 'Shield', last: 'Agent' },
    { email: 'crm@shield.com', mobile: '9000000004', roleCode: 'CRM_EXECUTIVE', deptCode: 'CRM', first: 'CRM', last: 'Executive' },
    { email: 'pharmacy@shield.com', mobile: '9000000005', roleCode: 'PHARMACY_PROVIDER', deptCode: 'PHARMACY', first: 'Pharmacy', last: 'Provider' },
    { email: 'clinic@shield.com', mobile: '9000000006', roleCode: 'DOCTOR', deptCode: 'CLINIC', first: 'Clinic', last: 'Doctor' },
    { email: 'dental@shield.com', mobile: '9000000007', roleCode: 'DENTAL_PROVIDER', deptCode: 'DENTAL', first: 'Dental', last: 'Provider' },
  ];

  const staffUsers: Record<string, any> = {};
  for (const staffInfo of staffData) {
    let user = await prisma.user.findUnique({
      where: { mobile: staffInfo.mobile },
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
          status: 'ACTIVE',
        },
      });
      console.log(`Created staff user: ${staffInfo.email} (${staffInfo.roleCode})`);
    } else {
      user = await prisma.user.update({
        where: { id: user.id },
        data: {
          passwordHash: 'Zabnix@2025',
          roleId: roles[staffInfo.roleCode].id,
          departmentId: departments[staffInfo.deptCode].id,
        },
      });
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

  const customerFixtures = [
    {
      key: 'nihal',
      customerCode: 'CUST-123456',
      aadhaarNumber: '112233445566',
      firstName: 'Nihal',
      lastName: 'Rahman',
      dob: '1990-05-15',
      bloodGroup: 'O+',
      agentCode: 'AGT-SAHAKAR-101',
      referralCode: 'REF-NIHAL-100',
      gender: 'MALE',
      mobile: '7034479800',
      email: 'nihal.rahman@shield.local',
      addressLine1: 'Nihal Villa, Melattur Road',
      city: 'Perinthalmanna',
      district: 'Malappuram',
      state: 'Kerala',
      pincode: '679322',
      membershipType: 'FOUNDING',
      membershipNumber: 'SHLD-2026-123456',
      joiningFee: 0,
      activationDate: '2026-01-01',
      expiryDate: '2027-01-01',
      cardNumber: 'SHLD-CARD-123456',
      qrCode: 'SHLD-CARD-123456-TOKEN',
      issuedBusinessCode: 'HYP-PERINTHALMANNA',
      issuedAt: '2026-01-01T10:00:00Z',
      credit: { limit: 3000, available: 3000, outstanding: 0, status: 'ACTIVE' },
      statusHistory: [
        { oldStatus: 'PENDING', newStatus: 'ACTIVE', changedBy: 'shield-executive', remarks: 'Onboarding approved after KYC verification', createdAt: '2026-01-01T09:30:00Z' },
      ],
      contacts: [
        { name: 'Faseela Rahman', relation: 'Spouse', mobile: '7034479811', isPrimary: true },
      ],
      walletTransactions: [
        { uuid: 'a0000000-0000-0000-0000-000000000001', type: 'CREDIT', subLedger: 'CASH', amount: 5500.00, remarks: 'Wallet recharge', createdBy: 'super-admin', date: '2026-06-01T10:30:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000002', type: 'DEBIT', subLedger: 'CASH', amount: 1200.00, remarks: 'Pharmacy purchase - SHIELD Hyper Pharmacy, Perinthalmanna', createdBy: 'pharmacy-staff', date: '2026-06-03T14:15:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000003', type: 'DEBIT', subLedger: 'CASH', amount: 500.00, remarks: 'Consultation fee - Dr. Haneefa, Manjeri', createdBy: 'clinic-staff', date: '2026-06-05T11:20:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000004', type: 'CREDIT', subLedger: 'CASH', amount: 2000.00, remarks: 'Bonus credit', createdBy: 'super-admin', date: '2026-06-10T09:00:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000005', type: 'DEBIT', subLedger: 'CASH', amount: 350.00, remarks: 'Lab test - CBC, Makkaraparamba', createdBy: 'clinic-staff', date: '2026-06-12T16:45:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000006', type: 'CREDIT', subLedger: 'POINTS', amount: 150.00, remarks: 'Referral bonus: registered customer Suneer K', createdBy: 'crm-executive', date: '2026-06-18T10:00:00Z' },
      ],
      appointments: [
        { key: 'appt-001', uuid: 'b0000000-0000-0000-0000-000000000001', provider: 'clinic-1', type: 'CLINIC', date: '2026-06-21T10:00:00Z', status: 'SCHEDULED', notes: 'Regular checkup', consultation: { doctorName: 'Dr. Haneefa P', diagnosis: 'Hypertension review', notes: 'Continue current medication and repeat BP monitoring.' } },
        { key: 'appt-002', uuid: 'b0000000-0000-0000-0000-000000000002', provider: 'dental-1', type: 'DENTAL', date: '2026-06-14T14:30:00Z', status: 'COMPLETED', notes: 'Scaling and polishing' },
        { key: 'appt-003', uuid: 'b0000000-0000-0000-0000-000000000003', provider: 'clinic-2', type: 'HOME_VISIT', date: '2026-06-24T09:00:00Z', status: 'SCHEDULED', notes: 'Blood pressure check' },
        { key: 'appt-004', uuid: 'b0000000-0000-0000-0000-000000000004', provider: 'lab-1', type: 'CLINIC', date: '2026-06-08T08:30:00Z', status: 'COMPLETED', notes: 'CBC blood test' },
      ],
      documents: [
        { key: 'doc-001', uuid: 'c0000000-0000-0000-0000-000000000001', file: 'Prescription_2026_06_15.pdf', path: '/documents/customers/CUST-123456/prescriptions/1.pdf', size: 154321, mime: 'application/pdf', type: 'prescription', status: 'APPROVED', uploadedBy: 'pharmacy-staff', date: '2026-06-15T10:30:00Z', classification: 'PRESCRIPTION', extractionText: 'Amlodipine 5mg once daily for 30 days', extractionStatus: 'COMPLETED', processingStage: 'approval' },
        { key: 'doc-002', uuid: 'c0000000-0000-0000-0000-000000000002', file: 'Lab_Report_CBC_2026_06_18.pdf', path: '/documents/customers/CUST-123456/lab_reports/2.pdf', size: 234567, mime: 'application/pdf', type: 'labReport', status: 'VALIDATED', uploadedBy: 'clinic-staff', date: '2026-06-18T14:20:00Z', classification: 'LAB_REPORT', extractionText: 'CBC normal. Hemoglobin 13.4 g/dL', extractionStatus: 'COMPLETED', processingStage: 'validation' },
        { key: 'doc-003', uuid: 'c0000000-0000-0000-0000-000000000003', file: 'Dental_Xray_2026_06_12.jpg', path: '/documents/customers/CUST-123456/dental/3.jpg', size: 1234567, mime: 'image/jpeg', type: 'dentalRecord', status: 'PROCESSING', uploadedBy: 'dental-staff', date: '2026-06-12T09:15:00Z', classification: 'DENTAL_RECORD', extractionText: 'Lower molar cleaning advised', extractionStatus: 'PROCESSING', processingStage: 'classification' },
        { key: 'doc-004', uuid: 'c0000000-0000-0000-0000-000000000004', file: 'Invoice_Pharmacy_2026_06_19.pdf', path: '/documents/customers/CUST-123456/invoices/4.pdf', size: 87654, mime: 'application/pdf', type: 'invoice', status: 'CLASSIFIED', uploadedBy: 'pharmacy-staff', date: '2026-06-19T16:45:00Z', classification: 'INVOICE', extractionText: 'Pharmacy bill with 3 items', extractionStatus: 'COMPLETED', processingStage: 'classification' },
      ],
      prescriptionLinks: [{ documentKey: 'doc-001', issueDate: '2026-06-15', appointmentKey: 'appt-001' }],
      labReportLinks: [{ documentKey: 'doc-002', reportDate: '2026-06-18', appointmentKey: 'appt-004' }],
      dentalRecordLinks: [{ appointmentKey: 'appt-002', treatmentName: 'Scaling and Polishing', notes: 'Advised scaling twice a year. Next visit in 6 months.' }],
      notifications: [
        { title: 'Wallet Credited on June 20', message: '₹500 credited to your wallet from SHIELD Hyper Pharmacy, Perinthalmanna on June 20, 2026', status: 'UNREAD', date: '2026-06-20T21:20:00Z' },
        { title: 'Appointment on June 21', message: 'Your appointment with Dr. Haneefa P at Manjeri is on June 21, 2026 at 10:00 AM', status: 'UNREAD', date: '2026-06-20T19:30:00Z' },
        { title: 'Document Approved', message: 'Your June 18 prescription upload has been approved', status: 'READ', date: '2026-06-19T11:00:00Z' },
        { title: 'Membership Renewed for June 2026', message: 'Your SHIELD membership for the Perinthalmanna cluster was renewed on June 15, 2026', status: 'READ', date: '2026-06-15T09:30:00Z' },
      ],
      complaint: { type: 'Billing delay', description: 'Delay in pharmacy invoice validation at Melattur branch', status: 'RESOLVED', createdAt: '2026-06-17T11:00:00Z' },
      crmTask: { dueDate: '2026-06-25T17:00:00Z', status: 'PENDING', notes: 'Follow up on BP and sugar levels checkup report validation' },
      crmActivity: { type: 'CALL', notes: 'Phone call to confirm digital membership card activation. Customer verified and details explained.', createdAt: '2026-06-16T14:30:00Z' },
      purchases: [
        { invoiceNumber: 'INV-CUST-123456-001', provider: 'pharmacy-1', totalAmount: 1200, discountAmount: 150, payableAmount: 1050, purchaseDate: '2026-06-03T14:15:00Z', items: [{ productCode: 'PARA650', quantity: 2, unitPrice: 45, totalPrice: 90 }, { productCode: 'MET500', quantity: 5, unitPrice: 90, totalPrice: 450 }] },
        { invoiceNumber: 'INV-CUST-123456-002', provider: 'lab-1', totalAmount: 350, discountAmount: 0, payableAmount: 350, purchaseDate: '2026-06-12T16:45:00Z', items: [{ productCode: 'CBC-PANEL', quantity: 1, unitPrice: 350, totalPrice: 350 }] },
      ],
    },
    {
      key: 'suneer',
      customerCode: 'CUST-223344',
      aadhaarNumber: '223344556677',
      firstName: 'Suneer',
      lastName: 'K',
      dob: '1986-09-22',
      bloodGroup: 'A+',
      agentCode: 'AGT-SAHAKAR-102',
      referralCode: 'REF-SUNEER-200',
      referredByCode: 'CUST-123456',
      gender: 'MALE',
      mobile: '7034479801',
      email: 'suneer.k@shield.local',
      addressLine1: 'Kizhakkethil House, Angadippuram',
      city: 'Perinthalmanna',
      district: 'Malappuram',
      state: 'Kerala',
      pincode: '679321',
      membershipType: 'STANDARD',
      membershipNumber: 'SHLD-2026-223344',
      joiningFee: 500,
      activationDate: '2026-03-01',
      expiryDate: '2027-03-01',
      cardNumber: 'SHLD-CARD-223344',
      qrCode: 'SHLD-CARD-223344-TOKEN',
      issuedBusinessCode: 'HYP-PERINTHALMANNA',
      issuedAt: '2026-03-01T11:00:00Z',
      credit: { limit: 1500, available: 900, outstanding: 600, status: 'ACTIVE' },
      statusHistory: [
        { oldStatus: 'PENDING', newStatus: 'VERIFIED', changedBy: 'shield-executive', remarks: 'Initial onboarding verified', createdAt: '2026-02-27T13:20:00Z' },
        { oldStatus: 'VERIFIED', newStatus: 'ACTIVE', changedBy: 'super-admin', remarks: 'Membership activated after payment confirmation', createdAt: '2026-03-01T10:50:00Z' },
      ],
      contacts: [
        { name: 'Shahana Suneer', relation: 'Spouse', mobile: '7034479851', isPrimary: true },
      ],
      walletTransactions: [
        { uuid: 'a0000000-0000-0000-0000-000000000101', type: 'CREDIT', subLedger: 'CASH', amount: 2500.00, remarks: 'Opening wallet preload', createdBy: 'super-admin', date: '2026-03-01T11:10:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000102', type: 'DEBIT', subLedger: 'CASH', amount: 600.00, remarks: 'Doctor consultation and medicine issue', createdBy: 'clinic-staff', date: '2026-04-10T10:15:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000103', type: 'CREDIT', subLedger: 'POINTS', amount: 120.00, remarks: 'Referral reward approved from Nihal chain', createdBy: 'crm-executive', date: '2026-05-20T09:00:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000104', type: 'DEBIT', subLedger: 'POINTS', amount: 40.00, remarks: 'Reward points redeemed for diagnostics discount', createdBy: 'crm-executive', date: '2026-06-11T12:30:00Z' },
      ],
      appointments: [
        { key: 'appt-101', uuid: 'b0000000-0000-0000-0000-000000000101', provider: 'clinic-1', type: 'CLINIC', date: '2026-04-10T09:45:00Z', status: 'COMPLETED', notes: 'Diabetes follow-up', consultation: { doctorName: 'Dr. Haneefa P', diagnosis: 'Type 2 diabetes follow-up', notes: 'Continue Metformin and repeat fasting sugar in 3 months.' } },
        { key: 'appt-102', uuid: 'b0000000-0000-0000-0000-000000000102', provider: 'lab-1', type: 'CLINIC', date: '2026-06-11T08:00:00Z', status: 'COMPLETED', notes: 'Fasting sugar and CBC' },
      ],
      documents: [
        { key: 'doc-101', uuid: 'c0000000-0000-0000-0000-000000000101', file: 'Suneer_Prescription_April.pdf', path: '/documents/customers/CUST-223344/prescriptions/1.pdf', size: 144321, mime: 'application/pdf', type: 'prescription', status: 'APPROVED', uploadedBy: 'clinic-staff', date: '2026-04-10T10:40:00Z', classification: 'PRESCRIPTION', extractionText: 'Metformin 500mg twice daily', extractionStatus: 'COMPLETED', processingStage: 'approval' },
        { key: 'doc-102', uuid: 'c0000000-0000-0000-0000-000000000102', file: 'Suneer_Lab_June.pdf', path: '/documents/customers/CUST-223344/lab_reports/2.pdf', size: 211111, mime: 'application/pdf', type: 'labReport', status: 'VALIDATED', uploadedBy: 'clinic-staff', date: '2026-06-11T14:20:00Z', classification: 'LAB_REPORT', extractionText: 'Fasting sugar slightly elevated', extractionStatus: 'COMPLETED', processingStage: 'validation' },
      ],
      prescriptionLinks: [{ documentKey: 'doc-101', issueDate: '2026-04-10', appointmentKey: 'appt-101' }],
      labReportLinks: [{ documentKey: 'doc-102', reportDate: '2026-06-11', appointmentKey: 'appt-102' }],
      dentalRecordLinks: [],
      notifications: [
        { title: 'Lab results available', message: 'Your June diagnostics report is ready for review.', status: 'UNREAD', date: '2026-06-11T15:00:00Z' },
        { title: 'Reward points updated', message: '120 reward points were credited after referral qualification.', status: 'READ', date: '2026-05-20T09:15:00Z' },
      ],
      complaint: { type: 'App reminder issue', description: 'Appointment reminder arrived after the visit time.', status: 'OPEN', createdAt: '2026-06-12T10:00:00Z' },
      crmTask: { dueDate: '2026-06-28T17:30:00Z', status: 'IN_PROGRESS', notes: 'Check follow-up adherence for diabetes review and lab explanation' },
      crmActivity: { type: 'FOLLOW_UP', notes: 'CRM executive explained lab summary and next appointment timeline.', createdAt: '2026-06-12T16:00:00Z' },
      purchases: [
        { invoiceNumber: 'INV-CUST-223344-001', provider: 'pharmacy-1', totalAmount: 600, discountAmount: 60, payableAmount: 540, purchaseDate: '2026-04-10T10:15:00Z', items: [{ productCode: 'MET500', quantity: 4, unitPrice: 90, totalPrice: 360 }, { productCode: 'OMEGA3', quantity: 1, unitPrice: 240, totalPrice: 240 }] },
      ],
    },
    {
      key: 'fathima',
      customerCode: 'CUST-334455',
      aadhaarNumber: '334455667788',
      firstName: 'Fathima',
      lastName: 'Sherin',
      dob: '1994-11-04',
      bloodGroup: 'B+',
      agentCode: 'AGT-SAHAKAR-103',
      referralCode: 'REF-FATHIMA-300',
      referredByCode: 'CUST-123456',
      gender: 'FEMALE',
      mobile: '7034479802',
      email: 'fathima.sherin@shield.local',
      addressLine1: 'Pallikkal House, Manjeri',
      city: 'Manjeri',
      district: 'Malappuram',
      state: 'Kerala',
      pincode: '676121',
      membershipType: 'FOUNDING',
      membershipNumber: 'SHLD-2026-334455',
      joiningFee: 0,
      activationDate: '2026-02-10',
      expiryDate: '2027-02-10',
      cardNumber: 'SHLD-CARD-334455',
      qrCode: 'SHLD-CARD-334455-TOKEN',
      issuedBusinessCode: 'HYP-MANJERI',
      issuedAt: '2026-02-10T10:15:00Z',
      credit: null,
      statusHistory: [
        { oldStatus: 'PENDING', newStatus: 'ACTIVE', changedBy: 'shield-executive', remarks: 'Founding campaign signup approved', createdAt: '2026-02-10T09:50:00Z' },
      ],
      contacts: [
        { name: 'Rasheed P', relation: 'Brother', mobile: '7034479861', isPrimary: true },
      ],
      walletTransactions: [
        { uuid: 'a0000000-0000-0000-0000-000000000201', type: 'CREDIT', subLedger: 'CASH', amount: 4200.00, remarks: 'Wallet recharge at Manjeri branch', createdBy: 'pharmacy-staff', date: '2026-02-10T10:30:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000202', type: 'DEBIT', subLedger: 'CASH', amount: 850.00, remarks: 'Dental consultation and cleaning package', createdBy: 'dental-staff', date: '2026-05-06T14:00:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000203', type: 'CREDIT', subLedger: 'POINTS', amount: 80.00, remarks: 'Preventive camp wellness reward', createdBy: 'super-admin', date: '2026-05-08T18:20:00Z' },
      ],
      appointments: [
        { key: 'appt-201', uuid: 'b0000000-0000-0000-0000-000000000201', provider: 'dental-1', type: 'DENTAL', date: '2026-05-06T13:30:00Z', status: 'COMPLETED', notes: 'Dental cleaning and oral hygiene review' },
        { key: 'appt-202', uuid: 'b0000000-0000-0000-0000-000000000202', provider: 'clinic-1', type: 'CLINIC', date: '2026-07-02T11:00:00Z', status: 'SCHEDULED', notes: 'General physician follow-up', consultation: { doctorName: 'Dr. Haneefa P', diagnosis: 'Migraine review', notes: 'Track headache triggers and hydration.' } },
      ],
      documents: [
        { key: 'doc-201', uuid: 'c0000000-0000-0000-0000-000000000201', file: 'Fathima_Dental_Record.jpg', path: '/documents/customers/CUST-334455/dental/1.jpg', size: 654321, mime: 'image/jpeg', type: 'dentalRecord', status: 'APPROVED', uploadedBy: 'dental-staff', date: '2026-05-06T15:00:00Z', classification: 'DENTAL_RECORD', extractionText: 'Scaling done. No cavity observed.', extractionStatus: 'COMPLETED', processingStage: 'approval' },
      ],
      prescriptionLinks: [],
      labReportLinks: [],
      dentalRecordLinks: [{ appointmentKey: 'appt-201', treatmentName: 'Scaling and Oral Hygiene Review', notes: 'No active caries. Suggested 6-month follow-up.' }],
      notifications: [
        { title: 'Upcoming physician visit', message: 'Your scheduled review at Smart Clinic Manjeri is on July 2, 2026.', status: 'UNREAD', date: '2026-06-28T10:00:00Z' },
      ],
      complaint: { type: 'Waiting time', description: 'Dental visit started 20 minutes late.', status: 'RESOLVED', createdAt: '2026-05-07T12:00:00Z' },
      crmTask: { dueDate: '2026-07-01T17:00:00Z', status: 'PENDING', notes: 'Reminder call for July physician review' },
      crmActivity: { type: 'CALL', notes: 'Confirmed follow-up slot and shared oral care reminders.', createdAt: '2026-06-29T11:00:00Z' },
      purchases: [
        { invoiceNumber: 'INV-CUST-334455-001', provider: 'dental-1', totalAmount: 850, discountAmount: 50, payableAmount: 800, purchaseDate: '2026-05-06T14:00:00Z', items: [{ productCode: 'DENT-CLEAN', quantity: 1, unitPrice: 850, totalPrice: 850 }] },
      ],
    },
    {
      key: 'jaseela',
      customerCode: 'CUST-445566',
      aadhaarNumber: '445566778899',
      firstName: 'Jaseela',
      lastName: 'K',
      dob: '1978-07-19',
      bloodGroup: 'AB-',
      agentCode: 'AGT-SAHAKAR-104',
      referralCode: 'REF-JASEELA-400',
      referredByCode: 'CUST-223344',
      gender: 'FEMALE',
      mobile: '7034479803',
      email: 'jaseela.k@shield.local',
      addressLine1: 'Noor Mahal, Alanallur',
      city: 'Alanallur',
      district: 'Palakkad',
      state: 'Kerala',
      pincode: '678601',
      membershipType: 'STANDARD',
      membershipNumber: 'SHLD-2026-445566',
      joiningFee: 500,
      activationDate: '2026-04-05',
      expiryDate: '2027-04-05',
      cardNumber: 'SHLD-CARD-445566',
      qrCode: 'SHLD-CARD-445566-TOKEN',
      issuedBusinessCode: 'HYP-PERINTHALMANNA',
      issuedAt: '2026-04-05T09:40:00Z',
      credit: { limit: 2000, available: 1400, outstanding: 600, status: 'ACTIVE' },
      statusHistory: [
        { oldStatus: 'PENDING', newStatus: 'ACTIVE', changedBy: 'shield-executive', remarks: 'Standard membership approved with homecare add-on', createdAt: '2026-04-05T09:10:00Z' },
      ],
      contacts: [
        { name: 'Najeeb K', relation: 'Son', mobile: '7034479871', isPrimary: true },
      ],
      walletTransactions: [
        { uuid: 'a0000000-0000-0000-0000-000000000301', type: 'CREDIT', subLedger: 'CASH', amount: 3000.00, remarks: 'Manual wallet recharge for homecare plan', createdBy: 'super-admin', date: '2026-04-05T10:10:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000302', type: 'DEBIT', subLedger: 'CASH', amount: 950.00, remarks: 'Home care visit with nursing support', createdBy: 'clinic-staff', date: '2026-06-20T09:30:00Z' },
      ],
      appointments: [
        { key: 'appt-301', uuid: 'b0000000-0000-0000-0000-000000000301', provider: 'clinic-2', type: 'HOME_VISIT', date: '2026-06-20T08:30:00Z', status: 'COMPLETED', notes: 'Home care hypertension monitoring', consultation: { doctorName: 'Dr. Jaseela K', diagnosis: 'Home visit BP review', notes: 'Stable BP. Continue low salt diet.' } },
      ],
      documents: [
        { key: 'doc-301', uuid: 'c0000000-0000-0000-0000-000000000301', file: 'Homecare_BP_Notes.pdf', path: '/documents/customers/CUST-445566/homecare/1.pdf', size: 92311, mime: 'application/pdf', type: 'other', status: 'APPROVED', uploadedBy: 'clinic-staff', date: '2026-06-20T10:00:00Z', classification: 'HOMECARE_NOTE', extractionText: 'BP 130/84. No edema. Continue medication.', extractionStatus: 'COMPLETED', processingStage: 'approval' },
      ],
      prescriptionLinks: [],
      labReportLinks: [],
      dentalRecordLinks: [],
      notifications: [
        { title: 'Home care note uploaded', message: 'Your visit note from June 20 has been added to your records.', status: 'READ', date: '2026-06-20T10:10:00Z' },
      ],
      complaint: { type: 'Reschedule request', description: 'Requested earlier home visit time slot next month.', status: 'OPEN', createdAt: '2026-06-21T08:30:00Z' },
      crmTask: { dueDate: '2026-07-05T10:00:00Z', status: 'PENDING', notes: 'Coordinate next home visit schedule with family' },
      crmActivity: { type: 'CALL', notes: 'Spoke with son regarding next homecare review window.', createdAt: '2026-06-22T13:00:00Z' },
      purchases: [
        { invoiceNumber: 'INV-CUST-445566-001', provider: 'clinic-2', totalAmount: 950, discountAmount: 100, payableAmount: 850, purchaseDate: '2026-06-20T09:30:00Z', items: [{ productCode: 'OMEGA3', quantity: 1, unitPrice: 240, totalPrice: 240 }] },
      ],
    },
    {
      key: 'aswin',
      customerCode: 'CUST-556677',
      aadhaarNumber: '556677889900',
      firstName: 'Aswin',
      lastName: 'Das',
      dob: '1998-01-11',
      bloodGroup: 'O-',
      agentCode: 'AGT-SAHAKAR-105',
      referralCode: 'REF-ASWIN-500',
      referredByCode: 'CUST-334455',
      gender: 'MALE',
      mobile: '7034479804',
      email: 'aswin.das@shield.local',
      addressLine1: 'Melethil House, Tirur',
      city: 'Tirur',
      district: 'Malappuram',
      state: 'Kerala',
      pincode: '676101',
      membershipType: 'STANDARD',
      membershipNumber: 'SHLD-2026-556677',
      joiningFee: 500,
      activationDate: '2026-05-15',
      expiryDate: '2027-05-15',
      cardNumber: 'SHLD-CARD-556677',
      qrCode: 'SHLD-CARD-556677-TOKEN',
      issuedBusinessCode: 'HYP-MANJERI',
      issuedAt: '2026-05-15T12:00:00Z',
      credit: null,
      statusHistory: [
        { oldStatus: 'PENDING', newStatus: 'ACTIVE', changedBy: 'shield-executive', remarks: 'Membership enabled from referral campaign', createdAt: '2026-05-15T11:30:00Z' },
      ],
      contacts: [
        { name: 'Deepa Das', relation: 'Mother', mobile: '7034479881', isPrimary: true },
      ],
      walletTransactions: [
        { uuid: 'a0000000-0000-0000-0000-000000000401', type: 'CREDIT', subLedger: 'CASH', amount: 1800.00, remarks: 'Initial wallet top-up', createdBy: 'super-admin', date: '2026-05-15T12:10:00Z' },
        { uuid: 'a0000000-0000-0000-0000-000000000402', type: 'DEBIT', subLedger: 'CASH', amount: 420.00, remarks: 'Lab diagnostics package', createdBy: 'clinic-staff', date: '2026-06-25T08:45:00Z' },
      ],
      appointments: [
        { key: 'appt-401', uuid: 'b0000000-0000-0000-0000-000000000401', provider: 'lab-1', type: 'CLINIC', date: '2026-06-25T08:30:00Z', status: 'COMPLETED', notes: 'Pre-employment lab screening' },
      ],
      documents: [
        { key: 'doc-401', uuid: 'c0000000-0000-0000-0000-000000000401', file: 'Aswin_Lab_Screening.pdf', path: '/documents/customers/CUST-556677/lab_reports/1.pdf', size: 123222, mime: 'application/pdf', type: 'labReport', status: 'VALIDATED', uploadedBy: 'clinic-staff', date: '2026-06-25T12:00:00Z', classification: 'LAB_REPORT', extractionText: 'Routine screening normal', extractionStatus: 'COMPLETED', processingStage: 'validation' },
      ],
      prescriptionLinks: [],
      labReportLinks: [{ documentKey: 'doc-401', reportDate: '2026-06-25', appointmentKey: 'appt-401' }],
      dentalRecordLinks: [],
      notifications: [
        { title: 'Screening report available', message: 'Your routine screening results are ready to download.', status: 'UNREAD', date: '2026-06-25T12:30:00Z' },
      ],
      complaint: { type: 'None', description: 'No active complaints. Seeded for queue coverage.', status: 'RESOLVED', createdAt: '2026-06-26T09:00:00Z' },
      crmTask: { dueDate: '2026-07-02T16:00:00Z', status: 'PENDING', notes: 'Collect feedback on first lab experience' },
      crmActivity: { type: 'SMS', notes: 'Shared onboarding follow-up and lab report download reminder.', createdAt: '2026-06-25T13:00:00Z' },
      purchases: [
        { invoiceNumber: 'INV-CUST-556677-001', provider: 'lab-1', totalAmount: 420, discountAmount: 20, payableAmount: 400, purchaseDate: '2026-06-25T08:45:00Z', items: [{ productCode: 'CBC-PANEL', quantity: 1, unitPrice: 350, totalPrice: 350 }] },
      ],
    },
  ];

  const createdCustomers: Record<string, any> = {};
  const createdWallets: Record<string, any> = {};

  const readDate = (value: string) => new Date(value);

  for (const fixture of customerFixtures) {
    let customer = await prisma.customer.findUnique({
      where: { customerCode: fixture.customerCode },
    });

    if (!customer) {
      customer = await prisma.customer.create({
        data: {
          uuid: randomUUID(),
          customerCode: fixture.customerCode,
          aadhaarNumber: fixture.aadhaarNumber,
          firstName: fixture.firstName,
          lastName: fixture.lastName,
          dob: readDate(fixture.dob),
          bloodGroup: fixture.bloodGroup,
          agentCode: fixture.agentCode,
          referralCode: fixture.referralCode,
          gender: fixture.gender,
          mobile: fixture.mobile,
          email: fixture.email,
          addressLine1: fixture.addressLine1,
          city: fixture.city,
          district: fixture.district,
          state: fixture.state,
          pincode: fixture.pincode,
          status: 'ACTIVE',
          createdBy: staffUsers['shield-executive'].id,
          approvedBy: staffUsers['super-admin'].id,
        },
      });
      console.log(`Created customer: ${fixture.firstName} ${fixture.lastName}`);
    } else {
      customer = await prisma.customer.update({
        where: { id: customer.id },
        data: {
          mobile: fixture.mobile,
          email: fixture.email,
          agentCode: fixture.agentCode,
          referralCode: fixture.referralCode,
          status: 'ACTIVE',
        },
      });
      console.log(`Updated existing customer: ${fixture.firstName} ${fixture.lastName}`);
    }

    createdCustomers[fixture.customerCode] = customer;

    let membership = await prisma.membership.findFirst({
      where: { customerId: customer.id },
    });
    if (!membership) {
      membership = await prisma.membership.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          membershipTypeId: membershipTypes[fixture.membershipType].id,
          membershipNumber: fixture.membershipNumber,
          joiningFee: fixture.joiningFee,
          activationDate: readDate(fixture.activationDate),
          expiryDate: readDate(fixture.expiryDate),
          status: 'ACTIVE',
        },
      });
    }

    let shieldCard = await prisma.shieldCard.findFirst({
      where: { customerId: customer.id },
    });
    if (!shieldCard) {
      await prisma.shieldCard.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          cardNumber: fixture.cardNumber,
          qrCode: fixture.qrCode,
          status: 'ACTIVE',
          issuedBusinessId: businesses[fixture.issuedBusinessCode].id,
          issuedAt: readDate(fixture.issuedAt),
        },
      });
    }

    let wallet = await prisma.wallet.findFirst({
      where: { customerId: customer.id },
    });
    if (!wallet) {
      wallet = await prisma.wallet.create({
        data: {
          uuid: randomUUID(),
          customerId: customer.id,
          status: 'ACTIVE',
        },
      });
    }
    createdWallets[fixture.customerCode] = wallet;

    for (const contact of fixture.contacts) {
      const existingContact = await prisma.customerContact.findFirst({
        where: {
          customerId: customer.id,
          name: contact.name,
          mobile: contact.mobile,
        },
      });
      if (!existingContact) {
        await prisma.customerContact.create({
          data: {
            customerId: customer.id,
            name: contact.name,
            relation: contact.relation,
            mobile: contact.mobile,
            isPrimary: contact.isPrimary,
          },
        });
      }
    }

    for (const statusEvent of fixture.statusHistory) {
      const existingStatusEvent = await prisma.customerStatusHistory.findFirst({
        where: {
          customerId: customer.id,
          newStatus: statusEvent.newStatus,
          remarks: statusEvent.remarks,
        },
      });
      if (!existingStatusEvent) {
        await prisma.customerStatusHistory.create({
          data: {
            uuid: randomUUID(),
            customerId: customer.id,
            oldStatus: statusEvent.oldStatus,
            newStatus: statusEvent.newStatus,
            changedBy: staffUsers[statusEvent.changedBy].id,
            remarks: statusEvent.remarks,
            createdAt: readDate(statusEvent.createdAt),
          },
        });
      }
    }

    for (const txn of fixture.walletTransactions) {
      const existingTxn = await prisma.walletTransaction.findFirst({
        where: { uuid: txn.uuid },
      });
      if (!existingTxn) {
        await prisma.walletTransaction.create({
          data: {
            uuid: txn.uuid,
            walletId: wallet.id,
            transactionType: txn.type,
            subLedgerType: txn.subLedger,
            amount: txn.amount,
            remarks: txn.remarks,
            createdBy: staffUsers[txn.createdBy].id,
            createdAt: readDate(txn.date),
          },
        });
      }
    }

    if (fixture.credit) {
      const credit = await prisma.creditAccount.findFirst({
        where: { customerId: customer.id },
      });
      if (!credit) {
        await prisma.creditAccount.create({
          data: {
            uuid: randomUUID(),
            customerId: customer.id,
            creditLimit: fixture.credit.limit,
            availableCredit: fixture.credit.available,
            outstandingAmount: fixture.credit.outstanding,
            status: fixture.credit.status,
          },
        });
      }
    }

    const appointments: Record<string, any> = {};
    for (const apptInfo of fixture.appointments) {
      let appt = await prisma.appointment.findUnique({
        where: { uuid: apptInfo.uuid },
      });

      if (!appt) {
        appt = await prisma.appointment.create({
          data: {
            uuid: apptInfo.uuid,
            customerId: customer.id,
            providerId: providers[apptInfo.provider].id,
            appointmentType: apptInfo.type,
            appointmentDate: readDate(apptInfo.date),
            status: apptInfo.status,
            remarks: apptInfo.notes,
          },
        });
      }
      appointments[apptInfo.key] = appt;

      const consultation =
        'consultation' in apptInfo ? apptInfo.consultation : undefined;
      if (consultation) {
        const existingConsultation = await prisma.consultation.findFirst({
          where: { appointmentId: appt.id },
        });
        if (!existingConsultation) {
          await prisma.consultation.create({
            data: {
              customerId: customer.id,
              appointmentId: appt.id,
              doctorName: consultation.doctorName,
              diagnosis: consultation.diagnosis,
              notes: consultation.notes,
            },
          });
        }
      }
    }

    const documents: Record<string, any> = {};
    for (const docInfo of fixture.documents) {
      let doc = await prisma.document.findUnique({
        where: { uuid: docInfo.uuid },
      });

      if (!doc) {
        doc = await prisma.document.create({
          data: {
            uuid: docInfo.uuid,
            customerId: customer.id,
            fileName: docInfo.file,
            storagePath: docInfo.path,
            fileSize: BigInt(docInfo.size),
            mimeType: docInfo.mime,
            documentType: docInfo.type,
            status: docInfo.status,
            uploadedBy: staffUsers[docInfo.uploadedBy].id,
            createdAt: readDate(docInfo.date),
          },
        });
      }
      documents[docInfo.key] = doc;

      const existingClassification = await prisma.documentClassification.findFirst({
        where: { documentId: doc.id, classification: docInfo.classification },
      });
      if (!existingClassification) {
        await prisma.documentClassification.create({
          data: {
            documentId: doc.id,
            classification: docInfo.classification,
            confidence: 96.5,
          },
        });
      }

      const existingExtraction = await prisma.documentExtraction.findFirst({
        where: { documentId: doc.id },
      });
      if (!existingExtraction) {
        await prisma.documentExtraction.create({
          data: {
            documentId: doc.id,
            extractedText: docInfo.extractionText,
            confidenceScore: 94.25,
            extractionStatus: docInfo.extractionStatus,
            createdAt: readDate(docInfo.date),
          },
        });
      }

      const existingProcessingLog = await prisma.documentProcessingLog.findFirst({
        where: { documentId: doc.id, stage: docInfo.processingStage },
      });
      if (!existingProcessingLog) {
        await prisma.documentProcessingLog.create({
          data: {
            documentId: doc.id,
            stage: docInfo.processingStage,
            status: docInfo.status,
            remarks: `${docInfo.classification} document processed for seeded customer history`,
            processedAt: readDate(docInfo.date),
          },
        });
      }
    }

    for (const item of fixture.prescriptionLinks) {
      const appointment = appointments[item.appointmentKey];
      const consultation = appointment
        ? await prisma.consultation.findFirst({ where: { appointmentId: appointment.id } })
        : null;
      const existingPrescription = await prisma.prescription.findFirst({
        where: { documentId: documents[item.documentKey].id },
      });
      if (!existingPrescription) {
        await prisma.prescription.create({
          data: {
            customerId: customer.id,
            consultationId: consultation?.id,
            documentId: documents[item.documentKey].id,
            issueDate: readDate(item.issueDate),
          },
        });
      }
    }

    for (const item of fixture.labReportLinks) {
      const existingLabReport = await prisma.labReport.findFirst({
        where: { documentId: documents[item.documentKey].id },
      });
      if (!existingLabReport) {
        await prisma.labReport.create({
          data: {
            customerId: customer.id,
            appointmentId: appointments[item.appointmentKey]?.id,
            documentId: documents[item.documentKey].id,
            reportDate: readDate(item.reportDate),
          },
        });
      }
    }

    for (const item of fixture.dentalRecordLinks) {
      const existingDentalRecord = await prisma.dentalRecord.findFirst({
        where: { appointmentId: appointments[item.appointmentKey]?.id },
      });
      if (!existingDentalRecord) {
        await prisma.dentalRecord.create({
          data: {
            customerId: customer.id,
            appointmentId: appointments[item.appointmentKey]?.id,
            treatmentName: item.treatmentName,
            notes: item.notes,
          },
        });
      }
    }

    for (const notif of fixture.notifications) {
      const existingNotification = await prisma.notification.findFirst({
        where: { customerId: customer.id, title: notif.title },
      });
      if (!existingNotification) {
        await prisma.notification.create({
          data: {
            customerId: customer.id,
            title: notif.title,
            message: notif.message,
            channel: 'IN_APP',
            status: notif.status,
            sentAt: readDate(notif.date),
          },
        });
      }
    }

    const existingComplaint = await prisma.complaint.findFirst({
      where: { customerId: customer.id, complaintType: fixture.complaint.type },
    });
    if (!existingComplaint) {
      await prisma.complaint.create({
        data: {
          customerId: customer.id,
          complaintType: fixture.complaint.type,
          description: fixture.complaint.description,
          status: fixture.complaint.status,
          createdAt: readDate(fixture.complaint.createdAt),
        },
      });
    }

    const existingCrmTask = await prisma.crmTask.findFirst({
      where: { customerId: customer.id, notes: fixture.crmTask.notes },
    });
    if (!existingCrmTask) {
      await prisma.crmTask.create({
        data: {
          customerId: customer.id,
          assignedTo: staffUsers['crm-executive'].id,
          dueDate: readDate(fixture.crmTask.dueDate),
          status: fixture.crmTask.status,
          notes: fixture.crmTask.notes,
        },
      });
    }

    const existingCrmActivity = await prisma.crmActivity.findFirst({
      where: { customerId: customer.id, notes: fixture.crmActivity.notes },
    });
    if (!existingCrmActivity) {
      await prisma.crmActivity.create({
        data: {
          customerId: customer.id,
          activityType: fixture.crmActivity.type,
          notes: fixture.crmActivity.notes,
          createdBy: staffUsers['crm-executive'].id,
          createdAt: readDate(fixture.crmActivity.createdAt),
        },
      });
    }

    for (const purchaseInfo of fixture.purchases) {
      let purchase = await prisma.purchase.findFirst({
        where: { invoiceNumber: purchaseInfo.invoiceNumber },
      });
      if (!purchase) {
        purchase = await prisma.purchase.create({
          data: {
            uuid: randomUUID(),
            customerId: customer.id,
            providerId: providers[purchaseInfo.provider].id,
            invoiceNumber: purchaseInfo.invoiceNumber,
            totalAmount: purchaseInfo.totalAmount,
            discountAmount: purchaseInfo.discountAmount,
            payableAmount: purchaseInfo.payableAmount,
            purchaseDate: readDate(purchaseInfo.purchaseDate),
          },
        });
      }

      for (const purchaseItem of purchaseInfo.items) {
        const existingPurchaseItem = await prisma.purchaseItem.findFirst({
          where: {
            purchaseId: purchase.id,
            productId: products[purchaseItem.productCode].id,
          },
        });
        if (!existingPurchaseItem) {
          await prisma.purchaseItem.create({
            data: {
              purchaseId: purchase.id,
              productId: products[purchaseItem.productCode].id,
              quantity: purchaseItem.quantity,
              unitPrice: purchaseItem.unitPrice,
              totalPrice: purchaseItem.totalPrice,
            },
          });
        }
      }
    }
  }

  for (const fixture of customerFixtures) {
    if (!fixture.referredByCode) {
      continue;
    }

    const customer = createdCustomers[fixture.customerCode];
    const referrer = createdCustomers[fixture.referredByCode];
    if (!customer || !referrer) {
      continue;
    }

    if (customer.referredById !== referrer.id) {
      await prisma.customer.update({
        where: { id: customer.id },
        data: { referredById: referrer.id },
      });
    }
  }

  const referralEventsData = [
    {
      referredCustomerCode: 'CUST-223344',
      referrerCustomerCode: 'CUST-123456',
      status: 'REWARDED',
      rewardPoints: 150,
      qualifyingReferenceType: 'PURCHASE',
      qualifyingInvoiceNumber: 'INV-CUST-223344-001',
      notes: 'Suneer completed first qualifying transaction after membership activation.',
      verifiedAt: '2026-03-02T10:30:00Z',
      qualifiedAt: '2026-04-10T10:20:00Z',
      rewardedAt: '2026-05-20T09:00:00Z',
    },
    {
      referredCustomerCode: 'CUST-334455',
      referrerCustomerCode: 'CUST-123456',
      status: 'QUALIFIED',
      rewardPoints: 120,
      qualifyingReferenceType: 'PURCHASE',
      qualifyingInvoiceNumber: 'INV-CUST-334455-001',
      notes: 'Fathima has qualified through dental usage and is pending reward posting.',
      verifiedAt: '2026-02-11T11:00:00Z',
      qualifiedAt: '2026-05-06T15:30:00Z',
    },
    {
      referredCustomerCode: 'CUST-445566',
      referrerCustomerCode: 'CUST-223344',
      status: 'VERIFIED',
      rewardPoints: 100,
      notes: 'Jaseela onboarding verified. Awaiting first qualifying transaction cycle closure.',
      verifiedAt: '2026-04-05T10:00:00Z',
    },
    {
      referredCustomerCode: 'CUST-556677',
      referrerCustomerCode: 'CUST-334455',
      status: 'PENDING',
      rewardPoints: 75,
      notes: 'Aswin referral registered and pending verification workflow.',
    },
  ];

  for (const event of referralEventsData) {
    const referredCustomer = createdCustomers[event.referredCustomerCode];
    const referrerCustomer = createdCustomers[event.referrerCustomerCode];
    const qualifyingPurchase = event.qualifyingInvoiceNumber
      ? await prisma.purchase.findFirst({
          where: { invoiceNumber: event.qualifyingInvoiceNumber },
        })
      : null;

    const existingEvent = await prisma.referralRewardEvent.findFirst({
      where: { referredCustomerId: referredCustomer.id },
    });

    if (!existingEvent) {
      await prisma.referralRewardEvent.create({
        data: {
          uuid: randomUUID(),
          referrerCustomerId: referrerCustomer.id,
          referredCustomerId: referredCustomer.id,
          referralCode: referrerCustomer.referralCode,
          status: event.status,
          rewardPoints: event.rewardPoints,
          qualifyingReferenceType: event.qualifyingReferenceType,
          qualifyingReferenceId: qualifyingPurchase?.id,
          notes: event.notes,
          verifiedAt: event.verifiedAt ? readDate(event.verifiedAt) : null,
          qualifiedAt: event.qualifiedAt ? readDate(event.qualifiedAt) : null,
          rewardedAt: event.rewardedAt ? readDate(event.rewardedAt) : null,
        },
      });
    }
  }

  console.log(`Seeded ${customerFixtures.length} customers with linked memberships, wallets, referrals, visits, documents, CRM records, and purchases.`);
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
