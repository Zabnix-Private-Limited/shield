import 'dotenv/config';
import { PrismaClient } from '@prisma/client';
import { PrismaPg } from '@prisma/adapter-pg';
import { Pool } from 'pg';
import { randomUUID } from 'crypto';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const adapter = new PrismaPg(pool);
const prisma = new PrismaClient({ adapter });

async function main() {
  console.log('Seeding SHIELD database...');

  // 1. Seed Roles
  const rolesData = [
    { code: 'customer', name: 'Customer', description: 'Patient / Member access' },
    { code: 'pharmacy-staff', name: 'Pharmacy Staff', description: 'Pharmacy sales and bill uploading' },
    { code: 'clinic-staff', name: 'Clinic Staff', description: 'Clinical consultation and report booking' },
    { code: 'dental-staff', name: 'Dental Staff', description: 'Dental clinical operations' },
    { code: 'crm-executive', name: 'CRM Executive', description: 'Customer relations and complaints' },
    { code: 'shield-executive', name: 'SHIELD Executive', description: 'Onboarding and verification approvals' },
    { code: 'manager', name: 'Manager', description: 'Credit limit overrides and reporting analytics' },
    { code: 'super-admin', name: 'Super Admin', description: 'Full system administration' },
  ];

  const roles: Record<string, any> = {};
  for (const roleInfo of rolesData) {
    let role = await prisma.role.findUnique({
      where: { code: roleInfo.code },
    });

    if (!role) {
      role = await prisma.role.create({
        data: {
          uuid: randomUUID(),
          code: roleInfo.code,
          name: roleInfo.name,
          description: roleInfo.description,
        },
      });
      console.log(`Created role: ${roleInfo.code}`);
    }
    roles[roleInfo.code] = role;
  }

  // 2. Seed Business
  let business = await prisma.business.findUnique({
    where: { code: 'SHG' },
  });

  if (!business) {
    business = await prisma.business.create({
      data: {
        uuid: randomUUID(),
        code: 'SHG',
        name: 'Sahakar Healthcare Group',
        businessType: 'HEALTHCARE_PROVIDER',
        status: 'ACTIVE',
      },
    });
    console.log('Created business: SHG');
  }

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

  // 5. Seed Staff Users (Mock Auth targets)
  const staffData = [
    { email: 'admin@shield.com', mobile: '9000000001', roleCode: 'super-admin', deptCode: 'ADMIN', first: 'Super', last: 'Admin' },
    { email: 'manager@shield.com', mobile: '9000000002', roleCode: 'manager', deptCode: 'ADMIN', first: 'Branch', last: 'Manager' },
    { email: 'executive@shield.com', mobile: '9000000003', roleCode: 'shield-executive', deptCode: 'ADMIN', first: 'Shield', last: 'Executive' },
    { email: 'crm@shield.com', mobile: '9000000004', roleCode: 'crm-executive', deptCode: 'CRM', first: 'CRM', last: 'Executive' },
    { email: 'pharmacy@shield.com', mobile: '9000000005', roleCode: 'pharmacy-staff', deptCode: 'PHARMACY', first: 'Pharmacy', last: 'Staff' },
    { email: 'clinic@shield.com', mobile: '9000000006', roleCode: 'clinic-staff', deptCode: 'CLINIC', first: 'Clinic', last: 'Staff' },
    { email: 'dental@shield.com', mobile: '9000000007', roleCode: 'dental-staff', deptCode: 'DENTAL', first: 'Dental', last: 'Staff' },
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
        },
      });
    }
    staffUsers[staffInfo.roleCode] = user;
  }

  // 6. Seed Service Providers
  const providersData = [
    { code: 'clinic-1', name: 'Smart Clinic Manjeri', type: 'CLINIC' },
    { code: 'clinic-2', name: 'Home Care Alanallur', type: 'HOME_VISIT' },
    { code: 'dental-1', name: 'Dentistry Melattur', type: 'DENTAL' },
    { code: 'lab-1', name: 'Laboratory Tirur', type: 'LABORATORY' },
    { code: 'pharmacy-1', name: 'SHIELD Hyper Pharmacy Perinthalmanna', type: 'PHARMACY' },
  ];

  const providers: Record<string, any> = {};
  for (const provInfo of providersData) {
    let provider = await prisma.serviceProvider.findFirst({
      where: { providerName: provInfo.name, businessId: business.id },
    });

    if (!provider) {
      provider = await prisma.serviceProvider.create({
        data: {
          uuid: randomUUID(),
          businessId: business.id,
          providerName: provInfo.name,
          providerType: provInfo.type,
          status: 'ACTIVE',
        },
      });
      console.log(`Created provider: ${provInfo.name}`);
    }
    providers[provInfo.code] = provider;
  }

  // 7. Seed Mock Customer (Nihal Rahman)
  let customer = await prisma.customer.findUnique({
    where: { mobile: '9876543210' },
  });

  if (!customer) {
    customer = await prisma.customer.create({
      data: {
        uuid: randomUUID(),
        customerCode: 'CUST-123456',
        aadhaarNumber: '112233445566',
        firstName: 'Nihal',
        lastName: 'Rahman',
        dob: new Date('1990-05-15'),
        gender: 'MALE',
        mobile: '9876543210',
        email: 'Zabnixprivatelimited@gmail.com',
        addressLine1: 'Nihal Villa, Melattur Road',
        city: 'Perinthalmanna',
        district: 'Malappuram',
        state: 'Kerala',
        pincode: '679322',
        status: 'ACTIVE',
      },
    });
    console.log('Created mock customer: Nihal Rahman');

    // Create Membership
    await prisma.membership.create({
      data: {
        uuid: randomUUID(),
        customerId: customer.id,
        membershipTypeId: membershipTypes['FOUNDING'].id,
        membershipNumber: 'SHLD-2026-123456',
        joiningFee: 0.00,
        activationDate: new Date('2026-01-01'),
        expiryDate: new Date('2027-01-01'),
        status: 'ACTIVE',
      },
    });
    console.log('Created membership for Nihal Rahman');

    // Create Shield Card
    await prisma.shieldCard.create({
      data: {
        uuid: randomUUID(),
        customerId: customer.id,
        cardNumber: 'SHLD-CARD-123456',
        qrCode: 'SHLD-CARD-123456-TOKEN',
        status: 'ACTIVE',
        issuedAt: new Date('2026-01-01T10:00:00Z'),
      },
    });
    console.log('Created Shield Card for Nihal Rahman');

    // Create Wallet
    const wallet = await prisma.wallet.create({
      data: {
        uuid: randomUUID(),
        customerId: customer.id,
        status: 'ACTIVE',
      },
    });
    console.log('Created Wallet for Nihal Rahman');

    // Create Wallet transactions matching ledger list
    const transactionsData = [
      { uuid: 'a0000000-0000-0000-0000-000000000001', type: 'CREDIT', amount: 5500.00, remarks: 'Wallet recharge', createdBy: staffUsers['super-admin'].id, date: new Date('2026-06-01T10:30:00Z') },
      { uuid: 'a0000000-0000-0000-0000-000000000002', type: 'DEBIT', amount: 1200.00, remarks: 'Pharmacy purchase - SHIELD Hyper Pharmacy, Perinthalmanna', createdBy: staffUsers['pharmacy-staff'].id, date: new Date('2026-06-03T14:15:00Z') },
      { uuid: 'a0000000-0000-0000-0000-000000000003', type: 'DEBIT', amount: 500.00, remarks: 'Consultation fee - Dr. Haneefa, Manjeri', createdBy: staffUsers['clinic-staff'].id, date: new Date('2026-06-05T11:20:00Z') },
      { uuid: 'a0000000-0000-0000-0000-000000000004', type: 'CREDIT', amount: 2000.00, remarks: 'Bonus credit', createdBy: staffUsers['super-admin'].id, date: new Date('2026-06-10T09:00:00Z') },
      { uuid: 'a0000000-0000-0000-0000-000000000005', type: 'DEBIT', amount: 350.00, remarks: 'Lab test - CBC, Makkaraparamba', createdBy: staffUsers['clinic-staff'].id, date: new Date('2026-06-12T16:45:00Z') },
    ];

    for (const txn of transactionsData) {
      await prisma.walletTransaction.create({
        data: {
          uuid: txn.uuid,
          walletId: wallet.id,
          transactionType: txn.type,
          amount: txn.amount,
          remarks: txn.remarks,
          createdBy: txn.createdBy,
          createdAt: txn.date,
        },
      });
    }
    console.log('Populated wallet transaction ledger history');

    // Create Credit Account
    await prisma.creditAccount.create({
      data: {
        uuid: randomUUID(),
        customerId: customer.id,
        creditLimit: 3000.00,
        availableCredit: 3000.00,
        outstandingAmount: 0.00,
        status: 'ACTIVE',
      },
    });
    console.log('Created Credit Account for Nihal Rahman');
  } else {
    await prisma.customer.update({
      where: { id: customer.id },
      data: {
        email: 'Zabnixprivatelimited@gmail.com',
      },
    });
    console.log('Updated existing mock customer Nihal Rahman email');
  }

  // 8. Seed Appointments
  const appointmentsData = [
    { key: 'appt-001', uuid: 'b0000000-0000-0000-0000-000000000001', provider: 'clinic-1', type: 'CLINIC', date: new Date('2026-06-21T10:00:00Z'), status: 'scheduled', doctor: 'Dr. Haneefa P', notes: 'Regular checkup' },
    { key: 'appt-002', uuid: 'b0000000-0000-0000-0000-000000000002', provider: 'dental-1', type: 'DENTAL', date: new Date('2026-06-14T14:30:00Z'), status: 'completed', doctor: 'Dr. Asna Basheer', notes: 'Scaling and polishing' },
    { key: 'appt-003', uuid: 'b0000000-0000-0000-0000-000000000003', provider: 'clinic-2', type: 'HOME_VISIT', date: new Date('2026-06-24T09:00:00Z'), status: 'scheduled', doctor: 'Dr. Jaseela K', notes: 'Blood pressure check' },
    { key: 'appt-004', uuid: 'b0000000-0000-0000-0000-000000000004', provider: 'lab-1', type: 'CLINIC', date: new Date('2026-06-08T08:30:00Z'), status: 'completed', doctor: 'Tirur Lab Desk', notes: 'CBC blood test' },
  ];

  const appointments: Record<string, any> = {};
  for (const apptInfo of appointmentsData) {
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
          appointmentDate: apptInfo.date,
          status: apptInfo.status.toUpperCase(),
          remarks: apptInfo.notes,
        },
      });
      console.log(`Created appointment: ${apptInfo.uuid}`);
    }
    appointments[apptInfo.key] = appt;
  }

  // 9. Seed Documents
  const documentsData = [
    { key: 'doc-001', uuid: 'c0000000-0000-0000-0000-000000000001', file: 'Prescription_2026_06_15.pdf', path: '/documents/customers/1/prescriptions/1.pdf', size: 154321, mime: 'application/pdf', type: 'prescription', status: 'approved', uploadedBy: 'pharmacy-staff', date: new Date('2026-06-15T10:30:00Z') },
    { key: 'doc-002', uuid: 'c0000000-0000-0000-0000-000000000002', file: 'Lab_Report_CBC_2026_06_18.pdf', path: '/documents/customers/1/lab_reports/2.pdf', size: 234567, mime: 'application/pdf', type: 'labReport', status: 'validated', uploadedBy: 'clinic-staff', date: new Date('2026-06-18T14:20:00Z') },
    { key: 'doc-003', uuid: 'c0000000-0000-0000-0000-000000000003', file: 'Dental_Xray_2026_06_12.jpg', path: '/documents/customers/1/dental/3.jpg', size: 1234567, mime: 'image/jpeg', type: 'dentalRecord', status: 'processing', uploadedBy: 'dental-staff', date: new Date('2026-06-12T09:15:00Z') },
    { key: 'doc-004', uuid: 'c0000000-0000-0000-0000-000000000004', file: 'Invoice_Pharmacy_2026_06_19.pdf', path: '/documents/customers/1/invoices/4.pdf', size: 87654, mime: 'application/pdf', type: 'invoice', status: 'classified', uploadedBy: 'pharmacy-staff', date: new Date('2026-06-19T16:45:00Z') },
  ];

  const documents: Record<string, any> = {};
  for (const docInfo of documentsData) {
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
          status: docInfo.status.toUpperCase(),
          uploadedBy: staffUsers[docInfo.uploadedBy].id,
          createdAt: docInfo.date,
        },
      });
      console.log(`Created document record: ${docInfo.file}`);
    }
    documents[docInfo.key] = doc;
  }

  // 10. Seed Prescriptions, Lab Reports, Dental Records
  let prescription = await prisma.prescription.findFirst({
    where: { documentId: documents['doc-001'].id },
  });
  if (!prescription) {
    await prisma.prescription.create({
      data: {
        customerId: customer.id,
        documentId: documents['doc-001'].id,
        issueDate: new Date('2026-06-15'),
      },
    });
    console.log('Linked prescription document relation');
  }

  let labReport = await prisma.labReport.findFirst({
    where: { documentId: documents['doc-002'].id },
  });
  if (!labReport) {
    await prisma.labReport.create({
      data: {
        customerId: customer.id,
        appointmentId: appointments['appt-004'].id,
        documentId: documents['doc-002'].id,
        reportDate: new Date('2026-06-18'),
      },
    });
    console.log('Linked lab report document relation');
  }

  let dentalRecord = await prisma.dentalRecord.findFirst({
    where: { appointmentId: appointments['appt-002'].id },
  });
  if (!dentalRecord) {
    await prisma.dentalRecord.create({
      data: {
        customerId: customer.id,
        appointmentId: appointments['appt-002'].id,
        treatmentName: 'Scaling and Polishing',
        notes: 'Advised scaling twice a year. Next visit in 6 months.',
      },
    });
    console.log('Created dental treatment record');
  }

  // 11. Seed Notifications
  const notificationsData = [
    { uuid: 'notif-001', title: 'Wallet Credited on June 20', message: '₹500 credited to your wallet from SHIELD Hyper Pharmacy, Perinthalmanna on June 20, 2026', status: 'UNREAD', date: new Date('2026-06-20T21:20:00Z') },
    { uuid: 'notif-002', title: 'Appointment on June 21', message: 'Your appointment with Dr. Haneefa P at Manjeri is on June 21, 2026 at 10:00 AM', status: 'UNREAD', date: new Date('2026-06-20T19:30:00Z') },
    { uuid: 'notif-003', title: 'Document Approved', message: 'Your June 18 prescription upload has been approved', status: 'READ', date: new Date('2026-06-19T11:00:00Z') },
    { uuid: 'notif-004', title: 'Membership Renewed for June 2026', message: 'Your SHIELD membership for the Perinthalmanna cluster was renewed on June 15, 2026', status: 'READ', date: new Date('2026-06-15T09:30:00Z') },
  ];

  for (const notif of notificationsData) {
    let notification = await prisma.notification.findFirst({
      where: { title: notif.title, customerId: customer.id },
    });

    if (!notification) {
      await prisma.notification.create({
        data: {
          customerId: customer.id,
          title: notif.title,
          message: notif.message,
          channel: 'IN_APP',
          status: notif.status,
          sentAt: notif.date,
        },
      });
      console.log(`Created notification: ${notif.title}`);
    }
  }

  // 12. Seed CRM Activities, CRM Tasks, Complaints
  let complaint = await prisma.complaint.findFirst({
    where: { customerId: customer.id },
  });
  if (!complaint) {
    await prisma.complaint.create({
      data: {
        customerId: customer.id,
        complaintType: 'Billing delay',
        description: 'Delay in pharmacy invoice validation at Melattur branch',
        status: 'RESOLVED',
        createdAt: new Date('2026-06-17T11:00:00Z'),
      },
    });
    console.log('Created customer complaint log');
  }

  let crmTask = await prisma.crmTask.findFirst({
    where: { customerId: customer.id },
  });
  if (!crmTask) {
    await prisma.crmTask.create({
      data: {
        customerId: customer.id,
        assignedTo: staffUsers['crm-executive'].id,
        dueDate: new Date('2026-06-25T17:00:00Z'),
        status: 'PENDING',
        notes: 'Follow up on BP and Sugar levels checkup report validation',
      },
    });
    console.log('Created CRM Follow-up task');
  }

  let crmActivity = await prisma.crmActivity.findFirst({
    where: { customerId: customer.id },
  });
  if (!crmActivity) {
    await prisma.crmActivity.create({
      data: {
        customerId: customer.id,
        activityType: 'CALL',
        notes: 'Phone call to confirm digital membership card activation. Customer verified and details explained.',
        createdBy: staffUsers['crm-executive'].id,
        createdAt: new Date('2026-06-16T14:30:00Z'),
      },
    });
    console.log('Created CRM interaction call activity log');
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
