From: Joel Granados <joel.granados@kernel.org>
Subject: [PATCH 0/6] docs: Remove false positives from check-sysctl-docs
Date: Tue, 01 Jul 2025 10:56:41 +0200
Message-Id: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAMmiY2gC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDcwND3azEdN3iyuLkkpyU/GRdYyMLw+RUc4NUI4skJaCegqLUtMwKsHn
 RsbW1ABH4LJxfAAAA
X-Change-ID: 20250701-jag-sysctldoc-3281ce70e28b
To: Kees Cook <kees@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1241;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=dP90U+P+CIJkX3PevzW9Eoc1cobYxd/SZNH6G2NvVvo=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhjot2AfezT7qOGdr19ioQfavdV9DUKox1i/
 DrrVSqP5eV72YkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoY6LdAAoJELqXzVK3
 lkFP7WIL/2XyjWIY8MH+O6PwTq1+qzC/LvN6NJLzZEpEAkcsfEkSuJEeRjN7SgwiHNPvmYhiUKt
 n6IGsJDdCa6bXWpNAIpADHqebELpG/nst/oScGmdBE/6wiVc3DEDdAYgkvzusitb8OPA7WVRL6i
 JQ5fYy+QD9Tnvgzdhgc6JO401DOJan7piJVygliiqxUZLgtvtQtxpUQXxi098HxW1F7pRWxzOL9
 PPzNJfPBF5lyn6+dnp5jtZPSTUfCbo8rnurr0yY8bRGaJMZ6Qbl385ThjpgfhL+ADpr9ahQXRHh
 ot8CQ0u0Tw0eC+T7XpltJ468fh2+Gl2NKVr0iBhIxbIeslSYPVsjI6HKWIYrfWMnN1lgwTT9WPC
 MbHrjgSVjEpcMquHSN17VQHuiVufWJ2ofuAR37q83LTsJ3oFfl8VYycqNijRwoMb5/rrNyyZiLZ
 ctjNJcj/ssk3hnu2IISO3wadRSJ9EqQ6b0cAMNoIYm9uk9X3ag8f0IzApiyCpFrlc52ECB0gFI6
 Pk=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Removed false positives from check-sysctl-docs where there where
ctl_tables that were implemented and had documentation but were being
marked as undocumented or unimplemented.

Besides adjusting the patterns in the check-sysctl-docs script, I also
corrected formatting in the kernel.rst and vm.rst doc files (no wording
changes!)

Please get back to me if you have any comment or suggestions
best

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
Joel Granados (6):
      docs: nixify check-sysctl-docs
      docs: Use skiplist when checking sysctl admin-guide
      docs: Add awk section for ucount sysctl entries
      docs: Remove colon from ctltable title in vm.rst
      docs: Replace spaces with tabs in check-sysctl-docs
      docs: Downgrade arm64 & riscv from titles to comment

 Documentation/admin-guide/sysctl/kernel.rst |  32 +++--
 Documentation/admin-guide/sysctl/vm.rst     |   8 +-
 scripts/check-sysctl-docs                   | 184 +++++++++++++++-------------
 3 files changed, 120 insertions(+), 104 deletions(-)
---
base-commit: 19272b37aa4f83ca52bdf9c16d5d81bdd1354494
change-id: 20250701-jag-sysctldoc-3281ce70e28b

Best regards,
-- 
Joel Granados <joel.granados@kernel.org>

