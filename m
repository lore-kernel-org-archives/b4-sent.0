From: Joel Granados <joel.granados@kernel.org>
Date: Tue, 01 Jul 2025 10:56:47 +0200
Subject: [PATCH 6/6] docs: Downgrade arm64 & riscv from titles to comment
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250701-jag-sysctldoc-v1-6-936912553f58@kernel.org>
References: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
In-Reply-To: <20250701-jag-sysctldoc-v1-0-936912553f58@kernel.org>
To: Kees Cook <kees@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Paul Walmsley <paul.walmsley@sifive.com>, 
 Palmer Dabbelt <palmer@dabbelt.com>, Albert Ou <aou@eecs.berkeley.edu>, 
 Alexandre Ghiti <alex@ghiti.fr>
Cc: linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 linux-doc@vger.kernel.org, linux-riscv@lists.infradead.org, 
 Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2491;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=vmReX47mqCLgmmgZzbo16/Xw5onF/bS5D530hw5Anx8=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGhjoutgafknIe4uDW/tuqngY3301IDb7siVv
 D+Ppdv3MEHYgIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJoY6LrAAoJELqXzVK3
 lkFPIqYMAIw2aha8NP8P8uQJTcXrqi1uSeSVBitGs7JzTKKQH03EcYNNRzfXlq0GvfmC694C68K
 589+Rg8OmUJyr8RY9P8gRir1sNTcfD377eXgw2JBiBuNYo3sjcy9AH74ytTRTmuKtgkfOgqLbQB
 L1t0O/8qy5g0lVo3UboWOEmAj28SisTNub/9IDCBLn/3YxVfeqlId3k6HJgp3E4Shr1Va8fwDHD
 DUGoZ45iqIKT4ZNSDZcTuZpo+kLYFF+Q1zDWD+vXV8BeBRbOblYB9Fq5dKKWWq4elk5K/LhMdyB
 ZwDosse7CN63dW+gi8zKu8wD1CcLQ7gBvQqcouX51yE/HMRlqiyIY8vvPhlOdzILOg7yZxdl5fh
 K5Swo/tIBbzJh5pPNb5A9s0wLS06nyLLFa7rKscBeWVqhHqUF0lU+Qbtd/wgiEowZt3jRumBlya
 qrzjEEq6B/3sp3UaVJUsfXH1j+4LAyb5+TgCSP4stcZ/rTULBR8x2KOtuq09XuOXDpQRa13oMI7
 lk=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove the title string ("====") from under arm64 & riscv and move them
to a commment under the perf_user_access sysctl. They are explanations,
*not* sysctls themselves

This effectively removes these two strings from appearing as not
implemented when the check-sysctl-docs script is run

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 Documentation/admin-guide/sysctl/kernel.rst | 32 +++++++++++++----------------
 1 file changed, 14 insertions(+), 18 deletions(-)

diff --git a/Documentation/admin-guide/sysctl/kernel.rst b/Documentation/admin-guide/sysctl/kernel.rst
index dd49a89a62d3542fa1a599f318dff26589e1d57b..c2683ce17b25821559d0c04914aea360440c7309 100644
--- a/Documentation/admin-guide/sysctl/kernel.rst
+++ b/Documentation/admin-guide/sysctl/kernel.rst
@@ -1014,30 +1014,26 @@ perf_user_access (arm64 and riscv only)
 
 Controls user space access for reading perf event counters.
 
-arm64
-=====
+* for arm64
+  The default value is 0 (access disabled).
 
-The default value is 0 (access disabled).
+  When set to 1, user space can read performance monitor counter registers
+  directly.
 
-When set to 1, user space can read performance monitor counter registers
-directly.
+  See Documentation/arch/arm64/perf.rst for more information.
 
-See Documentation/arch/arm64/perf.rst for more information.
+* for riscv
+  When set to 0, user space access is disabled.
 
-riscv
-=====
+  The default value is 1, user space can read performance monitor counter
+  registers through perf, any direct access without perf intervention will trigger
+  an illegal instruction.
 
-When set to 0, user space access is disabled.
+  When set to 2, which enables legacy mode (user space has direct access to cycle
+  and insret CSRs only). Note that this legacy value is deprecated and will be
+  removed once all user space applications are fixed.
 
-The default value is 1, user space can read performance monitor counter
-registers through perf, any direct access without perf intervention will trigger
-an illegal instruction.
-
-When set to 2, which enables legacy mode (user space has direct access to cycle
-and insret CSRs only). Note that this legacy value is deprecated and will be
-removed once all user space applications are fixed.
-
-Note that the time CSR is always directly accessible to all modes.
+  Note that the time CSR is always directly accessible to all modes.
 
 pid_max
 =======

-- 
2.47.2

