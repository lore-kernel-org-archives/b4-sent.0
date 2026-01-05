From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Subject: [PATCH RESEND 0/4] sound: codecs: wm8962: Assorted fixes
Date: Mon, 05 Jan 2026 04:02:07 +0100
Message-Id: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: patches@opensource.cirrus.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel@puri.sm, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=762;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=BFEjwR2Arkbv0ipELyTdtC+knjx5XiRnABAIKHUy6C0=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpWym6n9xvHh0j2pjLJ01JWDxoOXRTciSmqvnki
 5QYtEEyRMGJAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVspugAKCRDo8jXPO9vD
 /9OKEACWAiBMmbKqsQXmrIgmFV3OndDFb94kbTKo+0eXN3/n2Pq+VNRpgSmP9sH0/+oQf3leyAM
 s+iGF8g/m5n649kZB+f9czvF/Z9aJITpnhWC+RJVWspTmn+xyZM6EQF9QfxLa0AEaVtK/HTSBmv
 Jp1dp7QvSdM7KrtsOTxTjzf0hlh+ExxGTealX1Cf8XAiWXpdKqSPlOgNuSz9H9SN7FNGLTBV4ob
 nEHZsIA9jmqkVmnfbYmhZqIIaYmasbHrYlaujzdBove1I8yXkAdavmxKtPEkWdU0/D27pVRiatd
 oMiG4vmvgFcrCcLo64FWrSXPVoKLK3s0WFhTAuIECr8Jt0hmItNa5NXvp+QXEF/h8+C2JBolKor
 lnKKM2FYj1hffiE4CdC0FdKy32+Ay8A7znpuCRDr9yh3F2Xw0FYV7mjsnVfR1ZNTPG+e8gtt+oe
 WuU5jxBb/JA5CjBa1mj74P6wIFIaG3JxnCxL3x9iGxYv4NMpM4UCte8e0K7bUSvbHrHpMPyf5GY
 8cYyABvaAefvFG9w7EfH16XX+gktn78IyfCpztrrCuBYQF2eB7zTezUrPtJAYdMnvkI5vuG6j6Q
 NgffKhSgwbtXPYRomFulr1ZiHgndQKZvGnTDCtpPUsW7vHUu35EnOkxsMtBvc6JG7XMtWYaKSd4
 bzz2i77Ix1OnNrg==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Bunch of patches developed while working on Purism's Librem 5 phone.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
Sebastian Krzyszkowiak (4):
      ASoC: wm8962: Add WM8962_ADC_MONOMIX to "3D Coefficients" mask
      ASoC: wm8962: Don't disable SYSCLK if it's enabled via DAPM
      ASoC: wm8962: Don't report a microphone if it's shorted to ground on plug
      ASoC: wm8962: Don't mark WM8962_ADDITIONAL_CONTROL_4 as volatile

 sound/soc/codecs/wm8962.c | 18 +++++++++++++++---
 1 file changed, 15 insertions(+), 3 deletions(-)
---
base-commit: 9ace4753a5202b02191d54e9fdf7f9e3d02b85eb
change-id: 20260105-wm8962-l5-fixes-8cde049eb67d

Best regards,
-- 
Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>

