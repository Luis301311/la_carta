import { ValueTransformer } from 'typeorm';

/** Postgres devuelve NUMERIC como string; esto lo convierte a number. */
export const decimalTransformer: ValueTransformer = {
  to: (value?: number | null) => value,
  from: (value?: string | null) =>
    value === null || value === undefined ? value : parseFloat(value),
};
