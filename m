From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/7] x86: Kconfig cleanups and help text improvements
Date: Fri, 21 Mar 2025 21:48:42 +0100
Message-Id: <20250321-x86_x2apic-v3-0-b0cbaa6fa338@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAKrQ3WcC/43OSw6CMBSF4a2Qji1pL5WHI/dhiGnKRa5KS1pCQ
 MLeLSTOHf6D8+WsLKAnDOySrMzjRIGcjZGdEmY6bR/IqYnNQMBZZCD4XOb3GfRAhhdYQSNaZVT
 RsDgYPLY0H9itjt161/Ox86h/BIhKSlGqQspUZnmluOS9HtOns+azvK4O0uG9Ux2F0fnluDXBD
 v4/r7dt+wITVH5d2AAAAA==
X-Change-ID: 20250320-x86_x2apic-7e92d0f4c47d
To: Thomas Gleixner <tglx@linutronix.de>, Ingo Molnar <mingo@redhat.com>, 
 Borislav Petkov <bp@alien8.de>, Dave Hansen <dave.hansen@linux.intel.com>, 
 x86@kernel.org, "H. Peter Anvin" <hpa@zytor.com>, 
 Kees Cook <kees@kernel.org>, Jonathan Cameron <jic23@kernel.org>, 
 Lars-Peter Clausen <lars@metafoo.de>
Cc: linux-kernel@vger.kernel.org, Ingo Molnar <mingo@kernel.org>, 
 linux-iio@vger.kernel.org, 
 =?utf-8?q?Mateusz_Jo=C5=84czyk?= <mat.jonczyk@o2.pl>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1883; i=david@ixit.cz;
 h=from:subject:message-id; bh=CpTm/Ssh7UmOqET4ZoOlwg+ImY4NAduCep5IKrVt6F0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn3dCu7jynvXJK8lPJS6rk08IvynLIer67lxdKm
 KnBsXrlZ5+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ93QrgAKCRBgAj/E00kg
 cpCfEACDlc7AojeczQKU7Rbtzv5C9OW1PHbmmUkO/kclLeIxRlj4FEwSCmqUKbSsDgLXPT35xl+
 s4e0kajKOwaCE7BHBW0vlJsjKHpxOpMJH43hPLvsCoFzUpMfclQ6IJlktdZl3ckqPQAPnc1rr5B
 RtP+w/5sj8I+z513WpRM8Ta9WngD6LdyMsG3Cd83qWmVYsrftURiZH8j0ukWWoWj+Ekau1Bq4wy
 EPyrxqXGJtWpkqFmMiNQikO4fENYwYzynTnTE/XGGOSKL52w3Fv/yfy7YJnVHK2SsddSVu6d2GZ
 pJ+1YzdmfzjkH4fLMRmoPGuow01DYWjRJydkX4vgs/OgLI1rgnnOlRNyCVJfbUnM1KGvtuUU/cM
 s88ySZJ2cPQTEZDovxBoRfUjr3KEiXWuu5T/taK98wA2FsBYXtCdbnxDOJAHX3Wv+X7XydRo1nj
 tGlZEMCyF4ykoFtYhQe3pcyAm5HwE0ODvBFlLp1roDKw385mQq6LuGlWK0CgEMji49LEE87EFXg
 gneGtCI25l6A3sxISuYCYv/xdRrUNm78LDlaDwIUCYS1Y++mS7pzgEtH9ygMh/eXfckSJyidngr
 RTOKihB4C5lXSlFnadYozaUDSJZUYDhPwn094iGa61R8VjqEcyhPCCMdjJmTfoCH2MZHCQL5pzR
 ygzQhK/uzTmf40A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

I'm resending this mainly because of the first patch, but I find
all other patches worthy too, so here is the rebased bulk.

 - David
====

Hello,

There are some problems with Kconfig help texts in the kernel. They are
frequently confusing and use language that is difficult to understand
for people unfamiliar with the feature. Sometimes, the help text was not
updated after important kernel or ecosystem changes. References to
something "future" or "old" are also usually given without specifying
any dates.

First version of this patch series was sent out in February 2022.

Greetings,
Mateusz

Signed-off-by: Mateusz Jończyk <mat.jonczyk@o2.pl>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Rebased against latest next-20250321.
- Dropped deprecated patches:
   2/10  "x86/apic: fix panic message when x2APIC is not supported"
   4/10  "x86/Kconfig: drop X86_32_NON_STANDARD"
- Dropped patch I was not very sure about, as there are other refs:
   10/10 "x86/Kconfig: remove CONFIG_ISA_BUS"
- Link to v2: https://lore.kernel.org/r/20220911084711.13694-1-mat.jonczyk@o2.pl

---
Mateusz Jończyk (7):
      x86/Kconfig: Enable X86_X2APIC by default and improve help text
      x86/Kconfig: Always enable ARCH_SPARSEMEM_ENABLE
      x86/Kconfig: Move all X86_EXTENDED_PLATFORM options together
      x86/Kconfig: Update lists in X86_EXTENDED_PLATFORM
      x86/Kconfig: Document CONFIG_PCI_MMCONFIG
      x86/Kconfig: Make CONFIG_PCI_CNB20LE_QUIRK depend on X86_32
      x86/Kconfig: Document release year of glibc 2.3.3

 arch/x86/Kconfig | 85 ++++++++++++++++++++++++++++++++++++++------------------
 1 file changed, 58 insertions(+), 27 deletions(-)
---
base-commit: 9388ec571cb1adba59d1cded2300eeb11827679c
change-id: 20250320-x86_x2apic-7e92d0f4c47d

Best regards,
-- 
David Heidelberg <david@ixit.cz>

