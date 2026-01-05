From: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
Date: Mon, 05 Jan 2026 04:02:10 +0100
Subject: [PATCH RESEND 3/4] ASoC: wm8962: Don't report a microphone if it's
 shorted to ground on plug
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-wm8962-l5-fixes-v1-3-f4f4eeacf089@puri.sm>
References: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
In-Reply-To: <20260105-wm8962-l5-fixes-v1-0-f4f4eeacf089@puri.sm>
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Jaroslav Kysela <perex@perex.cz>, Takashi Iwai <tiwai@suse.com>
Cc: patches@opensource.cirrus.com, linux-sound@vger.kernel.org, 
 linux-kernel@vger.kernel.org, kernel@puri.sm, 
 Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1365;
 i=sebastian.krzyszkowiak@puri.sm; h=from:subject:message-id;
 bh=Ihi1/3FQbf8+c123/VfTZPL88wj1LxemPR2Lj4RLjvk=;
 b=owEBbQKS/ZANAwAKAejyNc8728P/AcsmYgBpWym6ai/WV0raWlCpeuwKy523q725Tu4P4N8Nh
 OwH1lYL7R6JAjMEAAEKAB0WIQQi3Z+uAGoRQ1g2YXzo8jXPO9vD/wUCaVspugAKCRDo8jXPO9vD
 /yeCD/9tWXBcouUQDNLf7cbS+4mOoaW1ESCxMuroGhxIfZiVfQqH5IFIG5uYG8hsUSasSqfVw65
 0oZPDVQGGA9+Oj8XlUb3fwqREW9Z14wp570QWasYHlHsT3bsd1/K/+8SpGCTsFxSowSMY8iJfsK
 rbM0gpBOnAHR8sQWUEBVsryVuMmM5puA9fj+Q3L62wVrgas4K0/oPcBsRHiUw8F7dz/mK1cPwhE
 egX9Rf1dh/tRkJSZci42lOauGbaFfVBc9iVcR8j0FSf0R9mkbTzgHdURsApkvqh92gqPxa7/Jip
 LXOiPJ2FFK1oTDhwiVFtEG0YNZYkiZ9TrGSgJ6ScBUpL43l+uy7sgCe0bQ4u3wnUEPuvYbCxF6A
 2I7KIOJc+EtpZKjv01msAdNe4Hck9cHCzYBvlmRP1eVgG1rHRtTCg9OGWyHO1kVpJorw+bcktnU
 0xFojry8K/1KEVMJCmZK8YB1H9i4SR2/xmUTGGfare/v2JK3a7JTtEER2kuh2aRp0L0geLczNzI
 /MfsDnm66jhyOZgDY48XNQtULZHit6LHIMLcGNPO8nZBgzHpKQvR1B4LlH1DC3tmCfRfatl38tN
 iiEfkXf0ru8evoDAnL9ac324RRCxsgyLIaDiVij5az8woOhhGY5BWbHZganenET+j1eSiEnqrSl
 DkykNT584BRejDw==
X-Developer-Key: i=sebastian.krzyszkowiak@puri.sm; a=openpgp;
 fpr=22DD9FAE006A11435836617CE8F235CF3BDBC3FF
X-Endpoint-Received: by B4 Relay for sebastian.krzyszkowiak@puri.sm/default with auth_id=32
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This usually means that a TRS plug with no microphone pin has been plugged
into a TRRS socket. Cases where a user is plugging in a microphone while
pressing a button will be handled via incoming interrupt after the user
releases the button, so the microphone will still be detected once it
becomes usable.

Signed-off-by: Sebastian Krzyszkowiak <sebastian.krzyszkowiak@puri.sm>
---
 sound/soc/codecs/wm8962.c | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/sound/soc/codecs/wm8962.c b/sound/soc/codecs/wm8962.c
index 843b8c6b40a4..dd73b4dc1b97 100644
--- a/sound/soc/codecs/wm8962.c
+++ b/sound/soc/codecs/wm8962.c
@@ -67,6 +67,8 @@ struct wm8962_priv {
 	struct mutex dsp2_ena_lock;
 	u16 dsp2_ena;
 
+	int mic_status;
+
 	struct delayed_work mic_work;
 	struct snd_soc_jack *jack;
 
@@ -3082,8 +3084,16 @@ static void wm8962_mic_work(struct work_struct *work)
 	if (reg & WM8962_MICSHORT_STS) {
 		status |= SND_JACK_BTN_0;
 		irq_pol |= WM8962_MICSCD_IRQ_POL;
+
+		/* Don't report a microphone if it's shorted right after
+		 * plugging in, as this may be a TRS plug in a TRRS socket.
+		 */
+		if (!(wm8962->mic_status & WM8962_MICDET_STS))
+			status = 0;
 	}
 
+	wm8962->mic_status = status;
+
 	snd_soc_jack_report(wm8962->jack, status,
 			    SND_JACK_MICROPHONE | SND_JACK_BTN_0);
 

-- 
2.52.0

