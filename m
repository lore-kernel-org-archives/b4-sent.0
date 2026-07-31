From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/2] Input: rmi4 - honor touchscreen-{x,y}-mm
Date: Fri, 31 Jul 2026 20:13:40 +0200
Message-Id: <20260731-respect-x-y-mm-v1-0-3e85a4bec745@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMTQ5AMBBA4avIrE1SJRquIhbFYCR+0kGIuLti+
 S3eu0DIMQnkwQWOdhaeJ48oDKDu7dQRcuMNWulUmThCR7JQveKBJ44jtiaxOjOKssqAjxZHLR/
 fsCh/y1YNvngvcN8PBHKtSXIAAAA=
X-Change-ID: 20260731-respect-x-y-mm-f74a2970e9b7
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: linux-input@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=722; i=david@ixit.cz;
 h=from:subject:message-id; bh=QH6rhX6GTBqhnnmniQGR0A1Bs7zSWu/v95M/i6cELvw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqbOXVtsLTJnFvCQFOknc7zX2vdae+YTc4iKEby
 WZq6CGfNRqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCamzl1QAKCRBgAj/E00kg
 csQED/0VgFmR2xTHUCDCPDe0mqBolsFDp5+W3ZPjiLKCeB7idnjlaZKLrUAq4F+waWqIDcZ5eyY
 u93uB39YgvDaCldllltCrwH7iK8W9HRXVeriJNTrhXu/EyGQ2GddGlS53bU+bs212GeztldG5/Z
 PV+x+ZVSUqh147cEtxcA/txBFEvsIeitrcv2PbBr5TxJDG5Mo9kgCqVCvmKVKxvM9QwPweK9XLc
 Nbg6ozRAHpiFJD4oDyrJeP7F3q8WXTt83zH6MbRH9DO1kbfTo+Utymaba3M11tAbXr8taywSIIL
 UMpEy/VG4fAXlAr27NZewJM1DxlFI7bYEUH63mjEQwQlFDbE9n/4zPk8itwkfWuUHf2XD/mFRxG
 eYRGTsn3lPChXifriWfooIa1rWshz7QajVv180HhjCYpcIcc45qAfVuVwLoHJcDUASVTxNSk3cw
 qIAXpEhr5EPysriXp+SO9ufPjc9HISQZkaHAwecrzpcM89lUFhDIjd1TU3end5xfSWnC7TeFDBw
 HAgnPrvN0spACKDzzlPUdlfEMqwKIejDgEcQukbL5faMZFF4nwcRK1OPIGoaFbfxDxiZEF0g/Wf
 WZTzfENjf1Kkd9WqwAXcCNoFbzDnlP8bAmshkaiZj197HIj8dSp1nVhTleFW6IFkdx5EST685BT
 6nsR7Mvvl5xxPXg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series ensures, that when invalid value is detected or mismatch
between value defined in the device-tree and the read from the
touchscreen is observed, the user is notified and zero is ignored.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
David Heidelberg (2):
      Input: rmi4 - report difference between platform data and detected coord in F12
      Input: rmi4 - fallback to platform data for x/y-mm in F12

 drivers/input/rmi4/rmi_f12.c | 33 +++++++++++++++++++++++++++++----
 1 file changed, 29 insertions(+), 4 deletions(-)
---
base-commit: 95d6a9ccef99117115e41e9adb271243bd5e985b
change-id: 20260731-respect-x-y-mm-f74a2970e9b7

Best regards,
--  
David Heidelberg <david@ixit.cz>

