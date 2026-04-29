+++
title = 'PDF tools'
date = '2026-04-25T20:35:29+02:00'
description = 'A CLI toolkit of focused Python utilities for PDF manipulation — merge, split, redact, encrypt, OCR, and more, with no rate limits or cloud dependencies.'
github = "https://github.com/krzyhon/pdf_tools"
tags = ["python", "pdf", "open-source"]
categories = ["python"]
featured = true
repo = "https://github.com/krzyhon/pdf_tools"
+++

# PDF Tools

A focused collection of single-purpose CLI utilities for PDF manipulation — built to run locally, offline, and without rate limits.

## Motivation

PDF workflows are a recurring pain point. Merging reports, splitting contracts, redacting sensitive data, making scanned documents searchable — these are tasks that come up regularly and never at a convenient time.

The typical solution is a free online tool. They work, but they come with friction: daily operation quotas, privacy concerns around uploading sensitive documents to third-party servers, and the workarounds that follow — clearing cookies, switching browsers, hunting for alternatives.

The obvious fix is a local toolchain. PDF manipulation is a solved problem in Python — libraries like `pypdf`, `PyMuPDF`, and `pytesseract` cover virtually every use case. The gap was just having purpose-built scripts for each operation rather than reaching for a web UI.

This toolkit was also an experiment in AI-assisted development. Python isn't my primary language, and building this from scratch would have meant a significant ramp-up. Using an LLM as a coding pair let me focus on the problem domain rather than library APIs — and the result is a set of tools I actually use.

> [!TIP]
> The source code is [here](https://github.com/krzyhon/pdf_tools).

## Stack

| Layer | Libraries |
|---|---|
| PDF parsing & manipulation | `pypdf`, `pymupdf` |
| OCR engine (optional) | `pytesseract`, `Pillow` |
| PDF-to-Word conversion | `pdf2docx` |
| Encryption | `cryptography` |
| Progress reporting | `tqdm` |

## Installation

```bash
pip install -r requirements.txt
```

**OCR support requires Tesseract** ([project page](https://github.com/tesseract-ocr/tesseract)):

```bash
# macOS
brew install tesseract

# Ubuntu / Debian
sudo apt install tesseract-ocr

# Windows
winget install UB-Mannheim.TesseractOCR
```

## Tools

| Script | Operation |
|---|---|
| `pdf_bookmarks.py` | Inspect and manage bookmarks / table of contents |
| `pdf_compressor.py` | Reduce file size via image and stream optimization |
| `pdf_decryptor.py` | Strip password protection from an encrypted PDF |
| `pdf_diff.py` | Visual diff between two PDF versions |
| `pdf_inspector.py` | Dump page coordinates — useful for targeting redactions |
| `pdf_merger.py` | Concatenate multiple PDFs into one |
| `pdf_ocr.py` | Run Tesseract OCR to produce a searchable, text-layer PDF |
| `pdf_page_numbers.py` | Stamp visible page numbers onto each page |
| `pdf_protector.py` | Encrypt a PDF with a user-supplied password |
| `pdf_redactor.py` | Permanently burn redaction boxes into the page (no hidden data) |
| `pdf_reorder.py` | Rearrange pages by specifying a new page order |
| `pdf_rotator.py` | Rotate individual pages or the entire document |
| `pdf_splitter.py` | Split a PDF by page ranges into separate files |
| `pdf_to_docx.py` | Convert a PDF to an editable Word document |
| `pdf_to_images.py` | Render each page to an image (PNG/JPEG) |
| `pdf_from_images.py` | Pack a set of images into a single PDF |
| `pdf_watermark.py` | Overlay a text watermark on every page |
