From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net 0/2] net/iucv: two fixes in the HiperSockets receive
 path
Date: Thu, 22 Oct 2026 21:48:33 -0500
Message-Id: <20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMyQrCQBAFfyW8sw2zZEF/RTzM0mp7GMN0IkLIv
 zvqsQqqNihXYcWp21D5JSrP0sAeOqR7KDcmyY3hjButcY5iT1l0puiHcLSDp5BNn9M0TtYHtGy
 ufJX3b3lG4QWXv9Q1Pjgt3xn2/QNSgGrJeQAAAA==
X-Change-ID: 20261022-b4-disp-b35a9153-ad04dc76713a
To: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 "David S. Miller" <davem@davemloft.net>, Paolo Abeni <pabeni@redhat.com>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Thorsten Winkler <twinkler@linux.ibm.com>
Cc: Nagamani PV <nagamani@linux.ibm.com>, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org, 
 Simon Horman <horms@kernel.org>, linux-kernel@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792723713; l=2328;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=BNJJOuLjMNRhAx5T7Da8KhKmOmXfQyl0MXLk28E4drE=;
 b=Z8InjL46QKi0duh6ud0YXgHDg5z3Pou/y/6UaKe6E6PVWr6eJPcSeyD1Nbzl6PFt6V64p3KHL
 SDS+sLZnONUCKabpDPw0vkcm6jMuVKIn0dYchNRPVsSb6Xk4/Y6fX4e
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Two bugs in the HiperSockets receive path that predate the socket-locking
rework [1]; review and testing of that rework turned them up. Neither
depends on it.

1/2 clears hs_dev before the socket drops its reference on the device and
marks the accesses that race with it: afiucv_hs_rcv() compares hs_dev
under iucv_sk_list.lock while close() clears it under lock_sock().
Hidayath Khan caught the racing pair with KCSAN under z/VM [2] and
suggested the fix. The listener's child now takes its device from the
frame instead of reading the listener's field in softirq. This is an
ordering fix with no known crash.

2/2 stops counting the SHT's empty frame against the receive window (the
peer does not count it) and drops the WARN_ON on the overrun path, which
a peer reaches from the network by sending past its window. Only frames
with data count now; a zero-length data frame, which already ends the
stream for its reader, is no longer counted either. 2/2 applies on its
own and goes to stable.

Based on net f4377bf85887. The same two patches apply on net-next
8df0638138d3, where the test set ran, and on mainline (7.3-rc7); the
SHT case below ran on this base as well. Tested on an s390x guest
under QEMU TCG with KASAN and lockdep on. QEMU has no HiperSockets
adapter and its s390x CPU emulation lacked things this needs: the
adapter is one I wrote, under the real qeth and qdio drivers, the CPU
carries my patches, and there is no IBM Z to compare against. With 2/2
an SHT read while frames wait in backlog_skb_q gives EOF instead of
WARN plus -EFAULT. 1/2 does not change any result in the rework's test
set; its race shows under KCSAN, not here. Logs on request.

[1] https://lore.kernel.org/netdev/20261011-b4-disp-410518f4-v1-1-753bf3258292@proton.me/
[2] https://lore.kernel.org/netdev/b3fea2ca-25ff-42c0-812c-f8cc6bb6667e@linux.ibm.com/

---
Bryam Vargas (2):
      net/iucv: clear hs_dev before dropping its reference
      net/iucv: do not count the SHT frame against the receive window

 net/iucv/af_iucv.c | 39 +++++++++++++++++++++++++++++----------
 1 file changed, 29 insertions(+), 10 deletions(-)
---
base-commit: f4377bf85887f57b59abb5479f7660a81ffe4449
change-id: 20261022-b4-disp-b35a9153-ad04dc76713a

Best regards,
--  
bryamzxz <hexlabsecurity@proton.me>

