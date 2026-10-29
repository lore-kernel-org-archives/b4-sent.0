From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net v2 0/2] net/iucv: two fixes in the HiperSockets receive
 path
Date: Wed, 28 Oct 2026 23:46:20 -0500
Message-Id: <20261028-b4-disp-dd3e4ebb-v2-0-3747658d59bd@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQrCMBAFf6Xs2YUkFmn9FfGQdF90PcSSbUUo/
 XejHmdgZiNDVRidu40qXmr6LA3CoaPpHssNrNKYggsn78LAqWdRm1nkiB4pcYb3Qx7FjTFSy+a
 KrO/f8kIFC13/0tb0wLR8Z7TvHyPtMV95AAAA
X-Change-ID: 20261028-b4-disp-dd3e4ebb-fe118f9d09aa
To: Thorsten Winkler <twinkler@linux.ibm.com>, 
 "David S. Miller" <davem@davemloft.net>, Jakub Kicinski <kuba@kernel.org>, 
 Alexandra Winter <wintera@linux.ibm.com>, 
 Eric Dumazet <edumazet@kernel.org>, Paolo Abeni <pabeni@redhat.com>
Cc: linux-s390@vger.kernel.org, Nagamani PV <nagamani@linux.ibm.com>, 
 linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 Hidayath Khan <hidayath@linux.ibm.com>, Simon Horman <horms@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793249180; l=3861;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=9bkBzsEfH1ypgz3kHKz5eZsv445/cpLKteXX+59ppss=;
 b=UCUr01jNTk+8uV+df1acsNPs1oHRikajSTatFtvl3XYxg0GGfQaPfD1UsrhD14Yj8d6t6rAca
 6tLBgClli4wAdTMsRdUzA6DFz9pA5i9al4wrZlobJK7EPXKDedkqZkF
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

Based on net at fcc00b15cb21, after the net-next merge (iucv_sock_close()
is split into __iucv_sock_close() there). The same two patches apply on
mainline. Tested on an s390x guest under QEMU TCG with KASAN and lockdep
on, on net f4377bf85887 and net-next 8df0638138d3; the base moved to
fcc00b15cb21 afterwards, same hunks. QEMU has no HiperSockets adapter:
the one here is mine, under the real qeth and qdio drivers, on a QEMU
with my own patches to the s390x machine (the adapter's interruptions
through the FLIC, a z/VM CP model), and there is no IBM Z to compare
against. With 2/2 an SHT read while frames wait in backlog_skb_q gives
EOF instead of WARN plus -EFAULT. 1/2 does not change any result in the
rework's test set; its race shows under KCSAN, not here. Logs on
request.

v2:
- 2/2: an empty frame read after the close over the window reached
  iucv_send_ctrl() with hs_dev already cleared (the AI review of v1
  [3]); the window update now goes out only while the socket is
  connected. Repro on the same machine (SO_MSGLIMIT 2, SO_RCVBUF 6144,
  two sends, one frame injected over the window, the SHT, 16 more
  behind it; the parameters are below 2/2), counting iucv_send_ctrl()
  entries and the frames at the adapter: v1 attempts one update after
  the close and nothing leaves; v2 attempts none. The reads are the same
  on both (1, 1, -EFAULT, -ECONNRESET, 0, -EFAULT; the last is a data
  frame behind the SHT closing again); net without the patch reads
  -EFAULT at the SHT with its WARN.
- 2/2: the commit message now says "a zero-length data frame that
  reaches recvmsg()": a zero-length send with a piggybacked credit is a
  window update and never reaches it [3].
- 1/2: code unchanged. The review's point on it (the child's device
  reference when a SYN races the listener's close) is the pre-existing
  orphan the notes below 1/2 describe; the rework [1] closes that race.
- Both commit messages say how the patch was tested.
- Rebased on net after the net-next merge.

v1: https://lore.kernel.org/netdev/20261022-b4-disp-b35a9153-v1-0-d74645876195@proton.me/

[1] https://lore.kernel.org/netdev/20261022-b4-disp-1d26b87a-v2-0-7ee1264d812a@proton.me/
[2] https://lore.kernel.org/netdev/b3fea2ca-25ff-42c0-812c-f8cc6bb6667e@linux.ibm.com/
[3] https://lore.kernel.org/netdev/179306942509.3134.1109951482403010755@kernel.org/

---
Bryam Vargas (2):
      net/iucv: clear hs_dev before dropping its reference
      net/iucv: do not count the SHT frame against the receive window

 net/iucv/af_iucv.c | 45 ++++++++++++++++++++++++++++++++++-----------
 1 file changed, 34 insertions(+), 11 deletions(-)
---
base-commit: fcc00b15cb21a6de76826e5012b2c758505f5e65
change-id: 20261028-b4-disp-dd3e4ebb-fe118f9d09aa

Best regards,
--  
bryamzxz <hexlabsecurity@proton.me>

