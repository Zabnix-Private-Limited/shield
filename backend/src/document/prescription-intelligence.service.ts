import {
  Injectable,
  ServiceUnavailableException,
} from '@nestjs/common';

type ProductMasterCandidate = {
  productId: string;
  productName: string;
  brand?: string | null;
  productCode?: string | null;
};

type AnalyzeFileRequest = {
  fileName: string;
  mimeType: string;
  buffer: Buffer;
  products: ProductMasterCandidate[];
};

export type PrescriptionAiMedicine = {
  name: string;
  confidence: number;
  dosage: string;
  duration: string;
  frequency: string;
};

export type PrescriptionAiMatchCandidate = {
  product_id: string;
  product_name: string;
  brand?: string | null;
  confidence: number;
};

export type PrescriptionAiMatch = {
  raw_name: string;
  matched_name?: string | null;
  confidence: number;
  status: string;
  dosage: string;
  duration: string;
  frequency: string;
  candidates: PrescriptionAiMatchCandidate[];
};

export type PrescriptionAiResponse = {
  patient: string;
  doctor: string;
  date: string;
  raw_text: string;
  medicines: PrescriptionAiMedicine[];
  medicine_matches: PrescriptionAiMatch[];
  overall_confidence: number;
  engine: string;
};

@Injectable()
export class PrescriptionIntelligenceService {
  private readonly defaultUrl = 'http://127.0.0.1:8010';

  private resolveBaseUrl() {
    return (
      process.env.PRESCRIPTION_AI_URL?.trim().replace(/\/+$/, '') ||
      this.defaultUrl
    );
  }

  async analyzeFile(
    payload: AnalyzeFileRequest,
  ): Promise<PrescriptionAiResponse> {
    const formData = new FormData();
    const fileBytes = new Uint8Array(payload.buffer);
    const blob = new Blob([fileBytes], {
      type: payload.mimeType || 'application/octet-stream',
    });

    formData.append('file', blob, payload.fileName);
    formData.append(
      'products',
      JSON.stringify(
        payload.products.map((product) => ({
          product_id: product.productId,
          product_name: product.productName,
          brand: product.brand ?? null,
          product_code: product.productCode ?? null,
        })),
      ),
    );

    try {
      const response = await fetch(`${this.resolveBaseUrl()}/analyze-file`, {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        const responseText = await response.text();
        throw new ServiceUnavailableException(
          `Prescription extraction service returned ${response.status}: ${responseText || 'Unknown failure'}`,
        );
      }

      return (await response.json()) as PrescriptionAiResponse;
    } catch (error) {
      if (error instanceof ServiceUnavailableException) {
        throw error;
      }

      const message =
        error instanceof Error ? error.message : 'Unknown connection failure';
      throw new ServiceUnavailableException(
        `Prescription extraction service is unavailable: ${message}`,
      );
    }
  }
}
