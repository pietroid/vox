import { baseUrlOf } from './base-url';

describe('baseUrlOf', () => {
  it('keeps a single origin as it is', () => {
    expect(baseUrlOf(['http://localhost:3000'])).toBe('http://localhost:3000');
  });

  it('answers on each host, falling back to the first', () => {
    expect(
      baseUrlOf(['https://vox.pietroteruya.dev', 'http://localhost:3000']),
    ).toEqual({
      allowedHosts: ['vox.pietroteruya.dev', 'localhost:3000'],
      fallback: 'https://vox.pietroteruya.dev',
      protocol: 'https',
    });
  });

  it('refuses an empty list', () => {
    expect(() => baseUrlOf([])).toThrow();
  });
});
