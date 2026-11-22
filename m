From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Subject: [PATCH v4 0/3] docs/translations/pt_BR: process: add
 handling-regressions.rst
Date: Sun, 22 Nov 2026 11:01:25 -0300
Message-Id: <20261122-handling-regressions-v4-0-b6b9f2070290@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/42Nyw7CIBBFf6VhLYZOSy2u/A/jgsdIMX0YqETT9
 N+FunGnyzO5c85CAnqHgRyLhXiMLrhpTFDvCqI7OVqkziQmwKApSwCajqZ3o6UerceQ94EKXkq
 umGYtMyS93j1e3XPTni8fDg91Qz1nV150LsyTf23dCHn3IxGBMgqcH4ziUom6OdlBun6vp4HkR
 Kz+kVRJgpXhKEULom6/Jeu6vgG0JapWDwEAAA==
X-Change-ID: 20261122-handling-regressions-951a5b0c080d
To: linux-doc@vger.kernel.org
Cc: corbet@lwn.net, skhan@linuxfoundation.org, danielmaraboo@gmail.com, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795356085; l=2059;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=piaR4pVX3njhKNRnfIxX/CMHnLB9/5ah13wj0salF4k=;
 b=KkXmyDkEZE0g/JHmRWS6jzCcLUuaCVAJ9XnBVNR5+xVsVO+vM9n9+pWtpha2+JglcJCrneGgD
 RHyXuhBP8aXBex+Hb3xsZoWo3RqlagiwHbz1LdsTwdrxfyykuKVC3cH
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the Brazilian Portuguese translation of
Documentation/process/handling-regressions.rst, the document that
describes what the "no regressions" rule means in practice for
developers.

The translation follows the original file as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns") and keeps
its structure: section levels, literal blocks, URLs, :ref: roles and the
regzbot commands are preserved verbatim.

It is split in three parts to keep the review tractable. The last patch
also wires the new document into the pt_BR process index.

Changes in v4:
- Join the section titles that were still split over two lines and give
  them a matching underline; one title had also lost its underline.
- Rejoin the two #regzbot command lines whose URL had been moved to the
  following line, which made the command unusable.
- Use a single "::" before literal blocks instead of ":::".

Changes in v3:
- Split the SPDX header back into two comment lines; the previous
  version merged them into one, which breaks the directive.
- Keep each section title on a single line with a matching underline.
- Replace the remaining "etiqueta" and "maintainer" occurrences with
  "tag" and "mantenedor", and use "flag day" consistently.
- Fix wording issues found on review: "nem sequer compila", "versão
  mainline ... de fato" instead of "adequada", and the AppArmor
  sentence.
- Keep proper nouns such as "Maintainers Summit 2024".

---
Eduardo Pereira Cruz (3):
      docs/translations/pt_BR: process: add handling-regressions.rst (1/3)
      docs/translations/pt_BR: process: add handling-regressions.rst (2/3)
      docs/translations/pt_BR: process: add handling-regressions.rst (3/3)

 .../pt_BR/process/handling-regressions.rst         | 1136 ++++++++++++++++++++
 1 file changed, 1136 insertions(+)
---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-handling-regressions-951a5b0c080d

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

