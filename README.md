# DocumentDB Samples Gallery

A curated collection of ready-to-run code samples showing how to build real-world applications with [DocumentDB](https://github.com/documentdb/documentdb) — an open-source, MongoDB-compatible document database built on PostgreSQL.

Browse the gallery at **[documentdb.github.io/samples](https://documentdb.github.io/samples)**.

---

## What's in this repo

Each top-level folder is a self-contained sample application:

```
documentdb-samples-gallery/
├── book-finder-js/          # AI-powered semantic book search (Node.js)
├── registry.yml             # Gallery metadata — edit this to add/update samples
└── ...
```

`registry.yml` is the source of truth for the gallery website. When a change to `registry.yml` is merged, the website automatically rebuilds and shows the updated list.

---

## Contributing a Sample

### 1. Build your sample

Create a new folder at the root of this repo with your sample code:

```
my-sample-name/
├── README.md          # required — explain what the sample does and how to run it
├── .env.example       # required if the sample uses env vars
├── .gitignore
└── src/
    └── ...
```

**Requirements for your sample folder:**
- A `README.md` that explains what it does, prerequisites, and how to run it
- A `.env.example` listing all required environment variables (never commit a real `.env`)
- Working code — the sample should run with `npm install && npm start` (or equivalent)

### 2. Register your sample

Add an entry to `registry.yml`:

```yaml
samples:
  - id: my-sample-name           # must match your folder name, kebab-case
    title: "My Sample Title"
    description: "One or two sentences describing what this sample demonstrates."
    language: Node.js            # see supported values below
    industry: AI/ML              # any descriptive string
    difficulty: Intermediate     # Beginner | Intermediate | Advanced
    tags:
      - Vector Search
      - OpenAI
    githubUrl: "https://github.com/documentdb/documentdb-samples-gallery/tree/main/my-sample-name"
```

**Supported `language` values** (controls the icon color on the gallery card):
`Python` · `Node.js` · `TypeScript` · `Go` · `Java` · `C#` · `Rust`

**`difficulty` must be exactly one of:** `Beginner` · `Intermediate` · `Advanced`

### 3. Open a pull request

```bash
git checkout -b feat/add-my-sample
git add my-sample-name/ registry.yml
git commit -m "feat: add my-sample-name"
git push origin feat/add-my-sample
```

Open a PR against `main`. Once merged, the gallery website rebuilds automatically.

---

## Samples

| Sample | Language | Difficulty | Tags |
|--------|----------|------------|------|
| [BookFinder: AI-Powered Semantic Book Discovery](./book-finder-js) | Node.js | Intermediate | Vector Search, OpenAI, Embeddings |

---

## How the gallery website works

The website ([documentdb.github.io](https://documentdb.github.io)) runs a build-time script that:

1. Clones this repo
2. Reads `registry.yml`
3. Generates the gallery page with search and filtering

No website code changes are needed when you add a sample — only `registry.yml` matters.

---

## License

Each sample carries its own license (see the `LICENSE` file in each folder). The registry itself is MIT licensed.
