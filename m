From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Subject: [PATCH 0/4] docs/translations/pt_BR: process: add
 maintainer-pgp-guide.rst
Date: Sun, 22 Nov 2026 13:08:42 -0300
Message-Id: <20261122-maintainer-pgp-guide-pt-br-v1-0-01ce5941c5c2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQrCMBBA0auUWTtgRiLVqxQXbTJJRzANk7QIp
 Xc36uIv3ubvUFiFC9y7HZQ3KbKkBnPqwM1jiozim4HOdDWGCF+jpNpixRwzxlU8Y644KTqyfbB
 8uwRvoQ2ycpD3bz48/i7r9GRXv0c4jg9plUbxfgAAAA==
X-Change-ID: 20261122-maintainer-pgp-guide-pt-br-c258f5e93fd5
To: linux-doc@vger.kernel.org
Cc: danielmaraboo@gmail.com, corbet@lwn.net, skhan@linuxfoundation.org, 
 rdunlap@infradead.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795363722; l=1429;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=JWQmIYmfYJWRTGYphpFzeIt5K+J+wEyD0NkQ7BIRMx8=;
 b=2uWxE7kBkuWoDcp1ct0swv99sMsPb52QNPYtS4l9S57EnjS1bAQiqPeSE3B+jMT6p7O5MmT3Z
 lKQITyBTW9vAcA+aqC+ALkRrPXn1POj+fmYRQWcAU37A6uP3IwCf/4h
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series adds the Brazilian Portuguese translation of
Documentation/process/maintainer-pgp-guide.rst, the guide that describes
how kernel maintainers should protect their PGP keys and use them to sign
tags, commits and patches.

The translation follows the English original as last changed by commit
fdd100ee60a0 ("docs: process: use gender-neutral pronouns") and keeps the
structure intact: all 41 section headings, the 20 cross-reference labels,
the note and warning directives, the 112 inline code spans and every gpg
command and key listing are preserved verbatim.

It is split in four parts by chapter so the review stays tractable. The
patches only add the translated file; nothing else changes.

---
Eduardo Pereira Cruz (4):
      docs/translations/pt_BR: process: add maintainer-pgp-guide.rst (1/4)
      docs/translations/pt_BR: process: add maintainer-pgp-guide.rst (2/4)
      docs/translations/pt_BR: process: add maintainer-pgp-guide.rst (3/4)
      docs/translations/pt_BR: process: add maintainer-pgp-guide.rst (4/4)

 Documentation/translations/pt_BR/process/index.rst |   1 +
 .../pt_BR/process/maintainer-pgp-guide.rst         | 922 +++++++++++++++++++++
 2 files changed, 923 insertions(+)
---
base-commit: 4405c18c95d2d0f99f6c581ef0ee8591a1aa6ccd
change-id: 20261122-maintainer-pgp-guide-pt-br-c258f5e93fd5

Best regards,
--  
Eduardo Pereira Cruz <dreduardocruz@gmail.com>

