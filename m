From: David Heidelberg <david@ixit.cz>
Date: Wed, 08 Oct 2025 16:05:30 +0200
Subject: [PATCH v2 3/7] arm64: dts: qcom: sdm845-oneplus-fajita: Use the
 freshly introduced driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251008-s6e3fc2x01-v2-3-21eca1d5c289@ixit.cz>
References: <20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz>
In-Reply-To: <20251008-s6e3fc2x01-v2-0-21eca1d5c289@ixit.cz>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=785; i=david@ixit.cz;
 h=from:subject:message-id; bh=q/p/oUY/pg0psfDX27C/axQezovaGYNjTnnvhN5F6iw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBo5m+o8WwYZzJmpGUawi0df9TqyDrWc1ltH2aT1
 c4H6sYwSvmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaOZvqAAKCRBgAj/E00kg
 cvyoEACS08aETUxyptP3uxV/seFzPvBW9ta1Gvhde2LowExWDfg5Oi7yiCc2xrzlmP22ycMyBDJ
 pvZrPP6QXzEe4ONdIedzl0tyZFDa+91qo/f0vdgymQR+fcTse55mY4L3qZI0QpWae2G7XjwRPAb
 kxIQOlpywvU+zZ4mwdf7JNh5y2+AcQUXFd0tac6uSoYB6gtdwK05m4GpQP0SNV6QgerdWP/3KGn
 z3hwmKCRXKPLosKWcd+Gdv/qwYIDEGl65mbf95Hg1FwTN2i3eOyXJN2oPdwZDFzb2UllkG7ck1T
 NwexZYDvhNLd2IncXUO9E4d2H2wAOxU0J14kpWKlNpGO6fCJVhOUv9K9p3Ho6rdKEXLwnVdjFv5
 fbpiSNiEddAi0dToxSNzFH9ewZnLDTLmDffVUHUT9w/IgwTwONI/a15FJeyHYADoR9g4LwTB5OX
 p0n8GNMBAJnvopl7cuIV/UQbi2XYjWkyun+z4bASaA+1GamhP7O/4pu3HeHOiNYXE3dhpxVMzh8
 w3GdGTluwzTAW9qkM9R0j+hHy4blUYmJAHkGy+ToTmVk8814FEzGdlx7GXbpYxHI/8ESOFZDcMe
 x0uh8K48GZgxuXH36OO+wOKqkrnz8MFy+QGMrei38bWpYq+aAy2IKRlunv981DwfNtdzlfdlzr8
 K/J2Tvp1X/K631w==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Switch from older effort to support different panels within one driver
(which already dropped support for the HW) to the freshly written one.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
index 7e75decfda052..55b3e94dd9726 100644
--- a/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
+++ b/arch/arm64/boot/dts/qcom/sdm845-oneplus-fajita.dts
@@ -32,7 +32,7 @@ battery: battery {
 &display_panel {
 	status = "okay";
 
-	compatible = "samsung,s6e3fc2x01";
+	compatible = "samsung,s6e3fc2x01-ams641rw";
 };
 
 &i2c4 {

-- 
2.51.0

