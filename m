From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] arm64: dts: qcom: sdm845-xiaomi: Recent firmware needs
 bigger XBL
Date: Wed, 16 Sep 2026 00:25:45 +0200
Message-Id: <20260916-sdm845-xbl-mem-v1-0-6e3c88507997@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrB0wQYP2KuJC40w7xVjJ2CKId
 zfa5Vv8v4NSFFJ4ZDtE+onKZ04weQb+1c9PQhmTwRbWFY1xqGOoywq3YcJAAY31rmTPXPcMKVo
 isWz3sO3+1u/wJr9eFziOE/n4X6JyAAAA
X-Change-ID: 20260916-sdm845-xbl-mem-12c64fcff8af
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Amit Pundir <amit.pundir@linaro.org>, 
 Molly Sophia <mollysophia379@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>
Cc: Konrad Dybcio <konradybcio@gmail.com>, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=790; i=david@ixit.cz;
 h=from:subject:message-id; bh=VZIygbDeKhSInpkJlp86QQMYBs3UwcY2IdgjnMm/luo=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqcXyimET/iGGEG5mbRbG1KhPkybeerM2oIatg
 7zjQcHqL9mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqnF8gAKCRBgAj/E00kg
 ciWJEACL8pVPY6lIDEYPoMdAZygN3sVA7hroVx+xUrCKDJF1IT/w4TE8vuYulkquzgBHSwbATfx
 fU9dfKfMH8DSELF0nggRDBCRXgKWRv/oDuDO0mpCjgNWHkISaB9EjoYYH2CceRK0qg7P9dBjVf8
 NGwpQYwW3Ce7Lc1QwZOjqkmRbP8SCqV/RXN7WZozzshUhZKByZATP7vxDOrS4knR2/SKDx1FKvT
 YFl52nU3vcix8+iHaWJBCQNjPZDpJGrs0iovjJj5KjbtthXZNIIkm74RmicYgwYE6MbszaH+p01
 29xse7M40PB2fIB8KcBvL3SHq1bv5R6YrSaDw7bD7877bwiTm283YbIkoNlv4B4D246PUwKcEgr
 LeQpKBvn5WNIXyWWBstANGamVkZbKuVgcylbudsWcnOSBrRh5HzfbDE1SCrpy5emFgNrTT7GXRj
 A0GiywxsKfktLs2BYb+s9nWRMzK7+b1oP8chZNSDlxYtLiiuhCc/eESDPkqrHXh/+/CjvPuKzZP
 R8g92xL9V95RMyO1zyoo6aSgT7t8qMIXZ6EyhKltGgKmegRQUqObQH1Pdr/cuwRzIqMTNWYxpX/
 OLf0ISOJqe1NznTTxgIcqxHAwjpvXaBjzsj2CAd6nnYTQBSQ1chBYare0+gnnZJE4exJrWjPLan
 DiB4+k7p6JTrVVg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Applies to all known Snapdragon 845 Xiaomi devices.

Verified against the vendor trees, only vendor trees with smaller XBL
are < Android 9.0.

Needs some Tested-by, I don't own any of these two devices.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      arm64: dts: qcom: sdm845-xiaomi-beryllium: Extend the xbl_mem region
      arm64: dts: qcom: sdm845-xiaomi-polaris: Extend the xbl_mem region

 arch/arm64/boot/dts/qcom/sdm845-xiaomi-beryllium-common.dtsi | 6 ++++++
 arch/arm64/boot/dts/qcom/sdm845-xiaomi-polaris.dts           | 6 ++++++
 2 files changed, 12 insertions(+)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260916-sdm845-xbl-mem-12c64fcff8af

Best regards,
--  
David Heidelberg <david@ixit.cz>

