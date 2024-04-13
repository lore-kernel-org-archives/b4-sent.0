From: Dmitry Safonov <0x7f454c46@gmail.com>
Subject: [PATCH net 0/4] selftests/net/tcp_ao: A bunch of fixes for TCP-AO
 selftests
Date: Sat, 13 Apr 2024 02:42:51 +0100
Message-Id: <20240413-tcp-ao-selftests-fixes-v1-0-f9c41c96949d@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIABvjGWYC/x2M0QqCQBBFf0XmuQE1i+hXoofZ2Wsu1Co7SwTiv
 zf6eM7l3JUMJcHo3qxU8E2W5uzQnRrSSfILnKIz9W0/tEN35qoLy8yG91hh1XhMPxhLFI3Xi4Z
 bEPJ4KTgGbx+UUenpMoiBQ5Gs0/75EasotG1/KEN2noYAAAA=
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Shuah Khan <shuah@kernel.org>
Cc: netdev@vger.kernel.org, linux-kselftest@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dmitry Safonov <0x7f454c46@gmail.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1712972582; l=913;
 i=0x7f454c46@gmail.com; s=20240410; h=from:subject:message-id;
 bh=KHPrFD1YMMjtcQAp8KwZm5roaOz4QkN4zvujtINqzO8=;
 b=g4UdatSWnniIGkEvTKc/9CPb83Xp944jIoxZpzLz9t1htXBnI3Aw6tuhEKco7FkzxCITkkCkOSFX
 jed5RYawCjbpGTDx15YXqwSBIGA97j352IR06NXZUMCi5/8jz2Ef
X-Developer-Key: i=0x7f454c46@gmail.com; a=ed25519;
 pk=cFSWovqtkx0HrT5O9jFCEC/Cef4DY8a2FPeqP4THeZQ=
X-Endpoint-Received: by B4 Relay for 0x7f454c46@gmail.com/20240410 with auth_id=152
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Started as addressing the flakiness issues in rst_ipv*, that affect
netdev dashboard.

Signed-off-by: Dmitry Safonov <0x7f454c46@gmail.com>
---
Dmitry Safonov (4):
      selftests/tcp_ao: Make RST tests less flaky
      selftests/tcp_ao: Zero-init tcp_ao_info_opt
      selftests/tcp_ao: Fix fscanf() call for format-security
      selftests/tcp_ao: Printing fixes to confirm with format-security

 tools/testing/selftests/net/tcp_ao/lib/proc.c      |  2 +-
 tools/testing/selftests/net/tcp_ao/lib/setup.c     | 12 +++++------
 tools/testing/selftests/net/tcp_ao/rst.c           | 23 ++++++++++++----------
 .../selftests/net/tcp_ao/setsockopt-closed.c       |  2 +-
 4 files changed, 21 insertions(+), 18 deletions(-)
---
base-commit: 8f2c057754b25075aa3da132cd4fd4478cdab854
change-id: 20240413-tcp-ao-selftests-fixes-adacd65cb8ba

Best regards,
-- 
Dmitry Safonov <0x7f454c46@gmail.com>

