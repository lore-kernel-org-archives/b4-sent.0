From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH 0/2] SM8475 sndcard support
Date: Wed, 29 Jul 2026 15:31:53 -0400
Message-Id: <20260729-sm8475-asoc-v1-0-3edad8aa7628@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrDWhFHUVsagajMRPOohE3F2x/
 BbvXcDoCBnK4AKHBzEts0ccBmAHM/coqPUGGcksyqUWPBVproThxYrEplqbWKkm0eCL1WFH53e
 r6t+8NyPa7V3AfT8mPdlYbwAAAA==
X-Change-ID: 20260729-sm8475-asoc-3c499a155b39
To: Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jaroslav Kysela <perex@perex.cz>, 
 Takashi Iwai <tiwai@suse.com>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785353516; l=647;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=ui8kY158w/vOloTWLLkXaCIXmhaSFnGgGqfPzLZawq8=;
 b=1+d8VGyqqsWjOa8B3JJOh0YCFB9hMiaVg5gN0neu3MKpkQpLSrqyH7k7NKnPARn+TaZDI5mcM
 SwGv8czX+ruB7gA1oSSm0yoi4B3vy9jX8+97aerhvp9sx1oTpUzlKrX
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the required bindings and driver support for supporting the sound
card found in the SM8475 SoC.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Esteban Urrutia (2):
      ASoC: dt-bindings: qcom,sm8250: Add compatible string for SM8475
      ASoC: qcom: sc8280xp: Add support for SM8475

 Documentation/devicetree/bindings/sound/qcom,sm8250.yaml | 1 +
 sound/soc/qcom/sc8280xp.c                                | 8 ++++++++
 2 files changed, 9 insertions(+)
---
base-commit: 78bc8af4affb9a732504eb22eeac7d1e50883853
change-id: 20260729-sm8475-asoc-3c499a155b39

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

