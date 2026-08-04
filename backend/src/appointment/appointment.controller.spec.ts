import { AppointmentController } from './appointment.controller';

describe('AppointmentController customer scope', () => {
  const appointmentService = {
    appointmentBelongsToCustomer: jest.fn(),
    findOne: jest.fn(),
  };
  const agentScope = { assertAgentCanAccessAppointment: jest.fn() };
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
});
