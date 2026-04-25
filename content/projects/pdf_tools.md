+++
title = 'PDF tools'
date = '2026-04-25T20:35:29+02:00'
description = 'Set of tools to operate on PDF files'
github = "https://github.com/krzyhon/pdf_tools"
tags = ["python", "pdf", "open-source"]
categories = ["python"]
featured = true
+++

# PDF Tools

A collection of command-line Python utilities for common PDF operations.

## Motivation
From time to time, I need to perform various operations on PDF files, such as merging, splitting, or hiding data. For a long time, I used free online tools for this purpose. The tools worked, but they only allowed a limited number of operations per day. Because of this, I had to look for others to complete the work, either clearing my cache, clearing my browser cache, or opening another browser window.

I finally decided to experiment. I admit that I'm not a Python developer, and writing such tools would take a lot of time. I would need to learn more about the Python environment, available packages, etc.

So, I decided to try doing it with AI support, and that's how this toolkit was created.

> [!TIP]
> The source code is [here](https://github.com/krzyhon/pdf_tools).

## Requirements

```bash
pip install -r requirements.txt
```

Python dependencies: `pypdf`, `pymupdf`, `tqdm`, `cryptography`, `pdf2docx`, `pytesseract`, `Pillow`

**System dependency for OCR only:** [Tesseract](https://github.com/tesseract-ocr/tesseract)

```bash
# macOS
brew install tesseract

# Ubuntu / Debian
sudo apt install tesseract-ocr

# Windows
winget install UB-Mannheim.TesseractOCR
```

## List of Tools
- [pdf_bookmarks.py — Manage bookmarks (table of contents)](https://github.com/krzyhon/pdf_tools#pdf_bookmarkspy--manage-bookmarks-table-of-contents])
- [pdf_compressor.py — Reduce file size](https://github.com/krzyhon/pdf_tools#pdf_compressorpy--reduce-file-size)
- [pdf_decryptor.py — Remove password protection](https://github.com/krzyhon/pdf_tools#pdf_decryptorpy--remove-password-protection)
- [pdf_diff.py — Compare two PDFs](https://github.com/krzyhon/pdf_tools#pdf_diffpy--compare-two-pdfs)
- [pdf_inspector.py — Find coordinates for redaction](https://github.com/krzyhon/pdf_tools#pdf_inspectorpy--find-coordinates-for-redaction)
- [pdf_merger.py — Merge multiple PDFs](https://github.com/krzyhon/pdf_tools#pdf_mergerpy--merge-multiple-pdfs)
- [pdf_ocr.py — Make scanned PDFs searchable](https://github.com/krzyhon/pdf_tools#pdf_ocrpy--make-scanned-pdfs-searchable)
- [pdf_page_numbers.py — Stamp page numbers](https://github.com/krzyhon/pdf_tools#pdf_page_numberspy--stamp-page-numbers)
- [pdf_protector.py — Encrypt with a password](https://github.com/krzyhon/pdf_tools#pdf_protectorpy--encrypt-with-a-password)
- [pdf_redactor.py — Permanently redact content](https://github.com/krzyhon/pdf_tools#pdf_redactorpy--permanently-redact-content)
- [pdf_reorder.py — Rearrange pages](https://github.com/krzyhon/pdf_tools#pdf_reorderpy--rearrange-pages)
- [pdf_rotator.py — Rotate pages](https://github.com/krzyhon/pdf_tools#pdf_rotatorpy--rotate-pages)
- [pdf_splitter.py — Split into multiple files](https://github.com/krzyhon/pdf_tools#pdf_splitterpy--split-into-multiple-files)
- [pdf_to_docx.py — Convert PDF to Word document](https://github.com/krzyhon/pdf_tools#pdf_to_docxpy--convert-pdf-to-word-document)
- [pdf_to_images.py — Convert pages to images](https://github.com/krzyhon/pdf_tools#pdf_to_imagespy--convert-pages-to-images)
- [pdf_from_images.py — Create PDF from images](https://github.com/krzyhon/pdf_tools#pdf_from_imagespy--create-pdf-from-images)
- [pdf_watermark.py — Stamp text watermark](https://github.com/krzyhon/pdf_tools#pdf_watermarkpy--stamp-text-watermark)
