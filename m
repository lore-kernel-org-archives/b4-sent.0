From: Michael Riesch <michael.riesch@collabora.com>
Subject: [PATCH v2 0/2] clang-format: format short enums and macro
 definitions correctly
Date: Thu, 10 Apr 2025 22:58:52 +0200
Message-Id: <20250210-clang-format-fixes-v2-0-37894413bbee@collabora.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAwx+GcC/32Oyw7CIBBFf6WZtWMA0VhX/ofpgsdgSWppgKCm4
 d/Fund57s19rJAoekpw6VaIVHzyYW4gdh2YUc13Qm8bg2DiyARnaKamogvxoTI6/6KEPZeWLKP
 TWVhowSXSZrTcbWg8+pRDfG8bhX/Vv3WFI8NeGycPSmqpxfUZJve7tp8pw1Br/QBMSKKruQAAA
 A==
To: Miguel Ojeda <ojeda@kernel.org>, Nathan Chancellor <nathan@kernel.org>, 
 Bill Wendling <morbo@google.com>, Justin Stitt <justinstitt@google.com>, 
 Nick Desaulniers <nick.desaulniers+lkml@gmail.com>
Cc: Collabora Kernel Team <kernel@collabora.com>, 
 linux-kernel@vger.kernel.org, llvm@lists.linux.dev, 
 Michael Riesch <michael.riesch@wolfvision.net>, 
 Michael Riesch <michael.riesch@collabora.com>
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1744318739; l=854;
 i=michael.riesch@collabora.com; s=20250410; h=from:subject:message-id;
 bh=LwjBjViQ0++5O1rnu8kLLZuctv/Nqm47sICzPz5fhgQ=;
 b=AxltgeguiGoVLirBm2lfFieJ2+Ym3S7GDtGCPVvTu0COqf4shBE8+SByAkyn8d/iMAzb/tSOd
 8ef+Vw0xqhaBaID5ULv19iDlKnM1KYUmU4H4aUExer89Tw/xfLUESuE
X-Developer-Key: i=michael.riesch@collabora.com; a=ed25519;
 pk=+MWX1fffLFZtTPG/I6XdYm/+OSvpRE8D9evQaWbiN04=
X-Endpoint-Received: by B4 Relay for michael.riesch@collabora.com/20250410 with auth_id=371
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Habidere,

These patches set two previously unset clang-format options to
(hopefully) sane values.

Looking forward to your comments!

Best regards,
Michael

Signed-off-by: Michael Riesch <michael.riesch@wolfvision.net>
Signed-off-by: Michael Riesch <michael.riesch@collabora.com>
---
Changes in v2:
- collected Nathan's Reviewed-by
- rebased onto v6.15-rc1
- Link to v1: https://lore.kernel.org/r/20250210-clang-format-fixes-v1-0-9bcf43a4b4b2@wolfvision.net

---
Michael Riesch (2):
      clang-format: do not allow short enums on a single line
      clang-format: align consecutive macros

 .clang-format | 2 ++
 1 file changed, 2 insertions(+)
---
base-commit: 0af2f6be1b4281385b618cb86ad946eded089ac8
change-id: 20250210-clang-format-fixes-914ded0e682d

Best regards,
-- 
Michael Riesch <michael.riesch@collabora.com>

