/**
 * Convert a human-readable title into a URL slug.
 *
 * @param input the raw title
 * @retuns the lowercased, hyphen-separated slug
 */
export function slugify(input: string): string {
  return input
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
}
