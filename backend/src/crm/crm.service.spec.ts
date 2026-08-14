import { BadRequestException } from '@nestjs/common';
import { CrmService } from './crm.service';

describe('CrmService complaint lifecycle', () => {
  const prisma = {
    complaint: { findUnique: jest.fn(), update: jest.fn() },
    complaintLifecycleEvent: { create: jest.fn() },
    user: { findFirst: jest.fn() },
    auditLog: { create: jest.fn() },
  };
  const service = new CrmService(prisma as any);
  const openComplaint = { id: 7n, status: 'SUBMITTED', assignedToUserId: null } as any;

  beforeEach(() => {
    jest.clearAllMocks();
    prisma.complaint.findUnique.mockResolvedValue(openComplaint);
    prisma.complaint.update.mockResolvedValue({ ...openComplaint, status: 'RESOLVED' });
    prisma.complaintLifecycleEvent.create.mockImplementation(({ data }) => Promise.resolve(data));
    prisma.auditLog.create.mockResolvedValue({});
  });

  it('persists an assignment and append-only ASSIGNED event', async () => {
    prisma.user.findFirst.mockResolvedValue({ id: 88n });
    await service.assignComplaint(7n, 88n, 42n, 'triage owner');
    expect(prisma.complaint.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ assignedToUserId: 88n, assignedAt: expect.any(Date) }) }));
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ eventType: 'ASSIGNED', fromAssigneeUserId: null, toAssigneeUserId: 88n, customerVisible: false }) }));
  });

  it('preserves prior assignment through a REASSIGNED history event', async () => {
    prisma.complaint.findUnique.mockResolvedValue({ ...openComplaint, assignedToUserId: 51n });
    prisma.user.findFirst.mockResolvedValue({ id: 88n });
    await service.assignComplaint(7n, 88n, 42n);
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ eventType: 'REASSIGNED', fromAssigneeUserId: 51n, toAssigneeUserId: 88n }) }));
  });

  it('never marks an internal note customer-visible', async () => {
    await service.addInternalNote(7n, 42n, 'Internal triage detail');
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ eventType: 'INTERNAL_NOTE_ADDED', customerVisible: false }) }));
  });

  it('records a status change as append-only history', async () => {
    await service.updateComplaint(7n, { status: 'IN_PROGRESS' }, 42n);
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ eventType: 'STATUS_CHANGED', actorUserId: 42n, customerVisible: false }) }));
  });

  it('marks a staff reply customer-visible and audits it', async () => {
    await service.replyToCustomer(7n, 42n, 'We are investigating this.');
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ eventType: 'CUSTOMER_REPLY_ADDED', customerVisible: true }) }));
    expect(prisma.auditLog.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ action: 'COMPLAINT_REPLIED' }) }));
  });

  it('requires an escalation reason and records ESCALATED history', async () => {
    await expect(service.escalateComplaint(7n, 42n, '  ')).rejects.toBeInstanceOf(BadRequestException);
    await service.escalateComplaint(7n, 42n, 'Provider confirmation required');
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ eventType: 'ESCALATED', customerVisible: false }) }));
  });

  it('requires a resolution note, records actor/time/note, and is retry safe', async () => {
    await expect(service.resolveComplaint(7n, 42n, '')).rejects.toBeInstanceOf(BadRequestException);
    await service.resolveComplaint(7n, 42n, 'Issue resolved.');
    expect(prisma.complaint.update).toHaveBeenCalledWith(expect.objectContaining({ data: expect.objectContaining({ status: 'RESOLVED', resolvedByUserId: 42n, resolvedAt: expect.any(Date), resolutionNote: 'Issue resolved.' }) }));
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledTimes(2);
    prisma.complaint.findUnique.mockResolvedValue({ ...openComplaint, status: 'RESOLVED' });
    await service.resolveComplaint(7n, 42n, 'Issue resolved.');
    expect(prisma.complaintLifecycleEvent.create).toHaveBeenCalledTimes(2);
  });
});
