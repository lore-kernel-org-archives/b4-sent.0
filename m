From: Demeter Barna <me@fromdisposition.org>
Date: Wed, 04 Nov 2026 18:07:09 +0000
Subject: [PATCH 1/7] dt-bindings: clock: qcom,sc8280xp-lpasscc: Add SM8350
 LPASS audio CSR
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261104-b4-sm8350-sound-v1-1-4c872df294fa@fromdisposition.org>
References: <20261104-b4-sm8350-sound-v1-0-4c872df294fa@fromdisposition.org>
In-Reply-To: <20261104-b4-sm8350-sound-v1-0-4c872df294fa@fromdisposition.org>
To: Bjorn Andersson <andersson@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Srinivas Kandagatla <srini@kernel.org>, 
 Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-sound@vger.kernel.org, Demeter Barna <me@fromdisposition.org>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793815654; l=1122;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=uLYdELyKXVAh9MvLIYStuylxx4awTFDCq7SbOgzzjnw=;
 b=bAj0U3eEhnrejkKNtVQFKlZ39o42GQzv9CEmwXty9EoSqncyDB2NWQHL8iwk7wg5UlIlwXgiV
 hkHtxEl+usVAs6otEOHuXKKvdxEDBzML3HXm+MYhm93pyQkP3CsT8jt
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

As on SC8280XP, the SM8350 LPASS audio CSR is controlled by the ADSP and
only provides resets to the OS, so it takes no clocks. Its resets are the
RX, TX and WSA SoundWire ones of SC7280 (at 0xa0, 0xa8 and 0xb0);
SC8280XP has no TX reset in this block, so there is no SC8280XP fallback
and the SC7280 reset IDs are used.

Signed-off-by: Demeter Barna <me@fromdisposition.org>
---
 Documentation/devicetree/bindings/clock/qcom,sc8280xp-lpasscc.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/clock/qcom,sc8280xp-lpasscc.yaml b/Documentation/devicetree/bindings/clock/qcom,sc8280xp-lpasscc.yaml
index f235b4e24..3d4a794ab 100644
--- a/Documentation/devicetree/bindings/clock/qcom,sc8280xp-lpasscc.yaml
+++ b/Documentation/devicetree/bindings/clock/qcom,sc8280xp-lpasscc.yaml
@@ -22,6 +22,7 @@ properties:
       - enum:
           - qcom,sc8280xp-lpassaudiocc
           - qcom,sc8280xp-lpasscc
+          - qcom,sm8350-lpassaudiocc
       - items:
           - const: qcom,x1e80100-lpassaudiocc
           - const: qcom,sc8280xp-lpassaudiocc

-- 
2.53.0

