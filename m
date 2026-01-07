From: David Heidelberg <david@ixit.cz>
Date: Wed, 07 Jan 2026 21:28:16 +0100
Subject: [PATCH v3 2/2] configs: Add google-pixel fragment config for Pixel
 3, 3 XL, 5
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pixel-config-v3-2-02a25e3fdcfa@ixit.cz>
References: <20260107-pixel-config-v3-0-02a25e3fdcfa@ixit.cz>
In-Reply-To: <20260107-pixel-config-v3-0-02a25e3fdcfa@ixit.cz>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de, Petr Vorel <petr.vorel@gmail.com>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, Simon Glass <sjg@chromium.org>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Matthew Croughan <matt@croughan.sh>, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=914; i=david@ixit.cz;
 h=from:subject:message-id; bh=h+Nc04IrcZG+c2wA/6MKW+Am3zzHGmDuKQCDq3RHC7o=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpXsHgAKzTizvWemARKtvkORLcddhSm0O/drIFU
 vG+EdEi3OOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaV7B4AAKCRBgAj/E00kg
 coNtD/9FawEBToqkb+y+9El/UCdcE6VxYQM+2Xd9RRC9SnduuhSSlaJbOr7fOuyhcpTpJ9m61ju
 b0GU1siqHDNfZCE7Smcq2Tyr4I0ZTiEb+DM/oniyHjNI/Rg9ZqgCNENuNvgjSz0MKuDnfyRfYdq
 BaPcmp+ZnbXogqaTqBcnhEUkC7DJ4xj/LjPeMoZABMdj/PV9cytgrxsAeD8SBgO8Yszs35DfFSX
 6iEK5z/3Iw7kp6xxW5pmF9r/UwrLv6DGSiR6TSyI8zVW/ybD4V9ohb54Y8P1e2cbKrLHr5682mE
 Kn7heA4FqtJ1RQdkuAgDe+IJnuRHXA7KTBDi5IR2fOQL+s16ap5HwYNCV8LoaQW21X+ehvj9S6P
 +bWr9qV/absE605KLAX5LLhcT6SIBnc6wsLc5nKP9wp9CrReT7uzZk2CtSgJxxD0vf/rzaoDwWz
 91gbrezK3W4/IWPsyxkcf+iQwJIFg3Z55sNo6Wrk7AIJV1qh63rRGvQHqwoQdDI/NN2aLtsp0rs
 Z/80ovoxxKUcWP4KU4ZII0zGtHl2DT1m7K5Ln/C55tpYLJ49GAid9loKNcb4mdcnq/3OGWUMw5L
 b/vhzovFLJzcQ/d8d/R8dwVRXfEzA22T4/CMrlqhb8hGa6lKS8U/GhgssJIJnsqCL/MaZ8KgGZr
 CMeGTRhMG7LLBew==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce a fragment config for the Pixel 3, Pixel 3 XL, Pixel 5.

On these devices, U-Boot is chainloaded via fastboot. However, due to
additional requirements added by google, the image header must have
a specific value for the text offset.
This is solved by setting CONFIG_TEXT_OFFSET to 0x80000 in U-Boot.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 board/qualcomm/google-pixel.config | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/board/qualcomm/google-pixel.config b/board/qualcomm/google-pixel.config
new file mode 100644
index 00000000000..999d4e45268
--- /dev/null
+++ b/board/qualcomm/google-pixel.config
@@ -0,0 +1,5 @@
+# Enables chainloading of U-Boot on Google Pixel phones using
+# newer bootloaders (Android Q/R)
+# Use for following devices: Pixel 3 (blueline), Pixel 3 XL (crosshatch),
+# Pixel 5 (redfin)...
+CONFIG_TEXT_BASE=0x80080000

-- 
2.51.0

