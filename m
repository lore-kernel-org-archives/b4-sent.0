From: Junrui Luo <moonafterrain@outlook.com>
Date: Mon, 17 Aug 2026 17:13:53 +0800
Subject: [PATCH] staging: sm750fb: do not program the PLL from an
 uninitialized value
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260817-sm750-fixes-v1-1-978c617e5a20@outlook.com>
X-B4-Tracking: v=1; b=H4sIANDQgmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0Nz3eJcc1MD3bTMitRiXRMzMwsTy5TEtLTUZCWgjoKiVLAEUEN0bG0
 tAHPAqKhdAAAA
X-Change-ID: 20260817-sm750-fixes-466849daffec
To: Sudip Mukherjee <sudipm.mukherjee@gmail.com>, 
 Teddy Wang <teddy.wang@siliconmotion.com>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: linux-fbdev@vger.kernel.org, linux-staging@lists.linux.dev, 
 linux-kernel@vger.kernel.org, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org, Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2027;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=HRMgLoAPLRsSpD1hPS4ZSJd8u0h8YfDKEqXGyACQ3KI=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrKYLF7+ZplxYUJTrlGCg+81odz9f3BKDHbNut7Mu+
 iG7vlOizryjlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJpJ4ipFhrV/XRqlP5zV/
 r9CNe7M75Nnd6e+TVv6Y0lm4Ye6BTg51DUaG21+/N/kUh97OmvvB46iYR4ChVFHRtWVsnJNjd1U
 J3JBnBwBydUz9
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

sm750_calc_pll_value() writes pll->M, N, OD and POD only when its search
loop finds a divider combination with 0 < M < 256, and returns 0 when
there is none. ddk750_set_mode_timing() discards that return value and
calls program_mode_registers() regardless, so sm750_format_pll_reg()
reads the four members uninitialized and pokes them into PANEL_PLL_CTRL
or CRT_PLL_CTRL. Nothing bounds var->pixclock on the way in, so a mode
set can ask for a clock the loop cannot represent.

Consume the return value and reject the mode; hw_sm750_crtc_set_mode()
already propagates a non-zero return. Initialize the structure as well:
sm750_calc_pll_value() returns early for SM750LE without writing the
members, and returns non-zero on that path.

Fixes: 81dee67e215b ("staging: sm750fb: add sm750 to staging")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 drivers/staging/sm750fb/ddk750_mode.c | 6 ++++--
 1 file changed, 4 insertions(+), 2 deletions(-)

diff --git a/drivers/staging/sm750fb/ddk750_mode.c b/drivers/staging/sm750fb/ddk750_mode.c
index 7163232c0701..5ff5226fe77a 100644
--- a/drivers/staging/sm750fb/ddk750_mode.c
+++ b/drivers/staging/sm750fb/ddk750_mode.c
@@ -205,12 +205,14 @@ static void program_mode_registers(struct mode_parameter *mode_param,
 
 int ddk750_set_mode_timing(struct mode_parameter *parm, enum clock_type clock)
 {
-	struct pll_value pll;
+	struct pll_value pll = {};
 
 	pll.input_freq = DEFAULT_INPUT_CLOCK;
 	pll.clock_type = clock;
 
-	sm750_calc_pll_value(parm->pixel_clock, &pll);
+	if (!sm750_calc_pll_value(parm->pixel_clock, &pll))
+		return -EINVAL;
+
 	if (sm750_get_chip_type() == SM750LE) {
 		/* set graphic mode via IO method */
 		outb_p(0x88, 0x3d4);

---
base-commit: f5bbbfec59b4e2fb7520a91de3df8a6174325d6a
change-id: 20260817-sm750-fixes-466849daffec

Best regards,
-- 
Junrui Luo <moonafterrain@outlook.com>

