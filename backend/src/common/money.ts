/** Redondea a 2 decimales para evitar errores de coma flotante en precios. */
export const round2 = (n: number) => Math.round(n * 100) / 100;
