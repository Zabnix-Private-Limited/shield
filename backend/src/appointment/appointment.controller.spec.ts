import { AppointmentController } from './appointment.controller';

describe('AppointmentController customer scope', () => {
  const appointmentService = {
    appointmentBelongsToCustomer: jest.fn(),
    findOne: jest.fn(),
    list: jest.fn(),
  };
  const agentScope = {
    assertAgentCanAccessAppointment: jest.fn(),
    assertAgentCanAccessCustomer: jest.fn(),
  };
  const controller = new AppointmentController(
    appointmentService as any,
    agentScope as any,
  );
  const customer = { principalType: 'CUSTOMER', customerId: '11' } as any;

  beforeEach(() => jest.clearAllMocks());

  it('rejects another customer appointment before reading it', async () => {
    appointmentService.appointmentBelongsToCustomer.mockResolvedValue(false);

    await expect(controller.findOne('99', customer)).rejects.toThrow(
      'Customers can only access their own appointments.',
    );
    expect(appointmentService.findOne).not.toHaveBeenCalled();
  });

  it('rejects staff-only consultation actions for customers', async () => {
    await expect(controller.startConsultation('99', customer)).rejects.toThrow(
      'This appointment action is for staff only.',
    );
  });

  it('projects customer appointments without private provider or customer fields', async () => {
    appointmentService.list.mockResolvedValue([
      {
        id: 9n,
        uuid: '00000000-0000-0000-0000-000000000009',
        customerId: 11n,
        providerId: 7n,
        appointmentType: 'CLINIC',
        appointmentDate: new Date('2026-08-09T10:00:00.000Z'),
        status: 'PENDING',
        remarks: 'Customer note',
        customer: { mobile: 'private' },
        provider: {
          id: 7n,
          providerName: 'Active Clinic',
          providerType: 'CLINIC',
          settlement: 'private',
          commission: 10,
        },
      },
    ]);

    const result = await controller.list(undefined, customer);
    const appointment = result.data[0];

    expect(appointment).toMatchObject({
      id: '9',
      customerId: '11',
      provider: { id: '7', providerName: 'Active Clinic', providerType: 'CLINIC' },
    });
    expect(appointment.provider).not.toHaveProperty('settlement');
    expect(appointment.provider).not.toHaveProperty('commission');
    expect(appointment).not.toHaveProperty('customer');
  });
});
