# Okapi website

A single self-contained page (`index.html`). Fonts, logo and screenshots are
embedded, so there is nothing to build. The PDF guide and social preview image
sit next to it.

## Deploy with GitHub (built in)

1. Repo **Settings › Pages › Build and deployment › Source**: choose
   **GitHub Actions** (one time).
2. Push to `main`. The **Deploy website** workflow publishes this folder.
3. The site appears under **Deployments** on the repo page at
   https://sanket-manohar.github.io/okapi/

Custom domain (optional): Settings › Pages › Custom domain, for example
`okapi.sanketmanohar.com`, then add the CNAME record GitHub shows at your
domain provider.
