From: Davide Cavalca <dcavalca@meta.com>
Date: Fri, 03 Nov 2023 23:33:42 +0000
Subject: [PATCH] rpm-pkg: simplify installkernel %post
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231103-rpmpost-v1-1-9c18afab47f4@meta.com>
X-B4-Tracking: v=1; b=H4sIAFWDRWUC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI2NDQwNj3aKC3IL84hLdNNNkS0tTUyNLQ8s0JaDqgqLUtMwKsEnRsbW1AG7
 r41lZAAAA
To: Masahiro Yamada <masahiroy@kernel.org>, 
 Nathan Chancellor <nathan@kernel.org>, 
 Nick Desaulniers <ndesaulniers@google.com>, 
 Nicolas Schier <nicolas@fjasle.eu>
Cc: linux-kbuild@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Davide Cavalca <dcavalca@meta.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1699054440; l=1637;
 i=dcavalca@meta.com; s=20231103; h=from:subject:message-id;
 bh=X5JC+W01uXiyXPVwSIF965qjWZWJ67z2pjY23Aa3nRA=;
 b=P/fwUPABI1VqrtkXrn3F4SbHZSLLxC/fFwBtcokkm2L/H4YTgu3ESNj4oYbXwAiF1LqOCDRrJ
 j9Hs9PSf7MaBETvJfqIJnlqTUHIMjYvwf+QJgK6vs4El3C26IFbFvpL
X-Developer-Key: i=dcavalca@meta.com; a=ed25519;
 pk=9b8tquSs5okUyZ8q4DQqRfT95N/++7b/GgqRBdqUDBU=
X-Endpoint-Received: by B4 Relay for dcavalca@meta.com/20231103 with auth_id=95
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The %post currently does a shuffling dance before calling installkernel.
This isn't actually necessary afaict, and the current implementation
ends up triggering downstream issues such as
https://github.com/systemd/systemd/issues/29568

This commit simplifies the logic to remove the shuffling. For reference,
the original logic was added in commit 3c9c7a14b627("rpm-pkg: add %post
section to create initramfs and grub hooks").

Signed-off-by: Davide Cavalca <dcavalca@meta.com>
---
 scripts/package/kernel.spec | 6 +-----
 1 file changed, 1 insertion(+), 5 deletions(-)

diff --git a/scripts/package/kernel.spec b/scripts/package/kernel.spec
index 3eee0143e0c5..cc4292c03ea2 100644
--- a/scripts/package/kernel.spec
+++ b/scripts/package/kernel.spec
@@ -77,11 +77,7 @@ rm -rf %{buildroot}
 
 %post
 if [ -x /sbin/installkernel -a -r /boot/vmlinuz-%{KERNELRELEASE} -a -r /boot/System.map-%{KERNELRELEASE} ]; then
-cp /boot/vmlinuz-%{KERNELRELEASE} /boot/.vmlinuz-%{KERNELRELEASE}-rpm
-cp /boot/System.map-%{KERNELRELEASE} /boot/.System.map-%{KERNELRELEASE}-rpm
-rm -f /boot/vmlinuz-%{KERNELRELEASE} /boot/System.map-%{KERNELRELEASE}
-/sbin/installkernel %{KERNELRELEASE} /boot/.vmlinuz-%{KERNELRELEASE}-rpm /boot/.System.map-%{KERNELRELEASE}-rpm
-rm -f /boot/.vmlinuz-%{KERNELRELEASE}-rpm /boot/.System.map-%{KERNELRELEASE}-rpm
+/sbin/installkernel %{KERNELRELEASE} /boot/vmlinuz-%{KERNELRELEASE} /boot/System.map-%{KERNELRELEASE}
 fi
 
 %preun

---
base-commit: e392ea4d4d00880bf94550151b1ace4f88a4b17a
change-id: 20231103-rpmpost-f5c99552919f

Best regards,
-- 
Davide Cavalca <dcavalca@meta.com>

