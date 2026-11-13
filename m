From: Patrick Fischer <admin@tsv-stahl-riesa.de>
Date: Fri, 13 Nov 2026 20:01:08 +0100
Subject: [PATCH] gpu: host1x: Cancel the fence when a syncpoint wait is
 interrupted
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261113-upstream-host1x-fence-cancel-v1-1-89f453504222@tsv-stahl-riesa.de>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQqDMBBA0avIrDuQSVChV5EuYhx1So2SiUUQ7
 9603Xx4m3+CchJWuFcnJH6LyhoL6FZBmH2cGGUoBmtsQ0QO901zYr/gvGqmA0eOgTH40hea3tm
 2dlSboYGy2BKPcvz23eNv3fsnh/x9wnV9AEi9W5aAAAAA
X-Change-ID: 20261113-upstream-host1x-fence-cancel-0b32753150d6
To: Thierry Reding <thierry.reding@kernel.org>, 
 Mikko Perttunen <mperttunen@nvidia.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, Jonathan Hunter <jonathanh@nvidia.com>
Cc: Svyatoslav Ryhel <clamor95@gmail.com>, dri-devel@lists.freedesktop.org, 
 linux-tegra@vger.kernel.org, linux-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Patrick Fischer <admin@tsv-stahl-riesa.de>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794596477; l=3463;
 i=admin@tsv-stahl-riesa.de; s=20261020; h=from:subject:message-id;
 bh=ma0XREdmMy4ffQO85e1k8ga8QFqtOsd1gUnED0Gj8hE=;
 b=AImcND9Q3ZBs1nzv3pd5kyP7ZjsNI4ynf7JGlkn7e2QDU+r4vkwsg/ERQOsPjn3m9xClaHAtL
 mdSJsZhynNYD/ylWY3E4gANZDqR6pT+R4sgotTBPNapj1yu34n/itpn
X-Developer-Key: i=admin@tsv-stahl-riesa.de; a=ed25519;
 pk=D+v6EloYcEY9PIUHFyTM5sqcGIU/fIXzLUdkR8vjAtk=
X-Endpoint-Received: by B4 Relay for admin@tsv-stahl-riesa.de/20261020 with auth_id=1251
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

host1x_syncpt_wait() creates its fence without the internal 30 second
timeout and cancels it only when dma_fence_wait_timeout() returns 0.
If the wait is interrupted, dma_fence_wait_timeout() returns
-ERESTARTSYS and the fence is left on the syncpoint's fence list,
holding the reference that host1x_syncpt_fence_enable_signaling() took
for the interrupt path. It is freed only once the syncpoint reaches the
threshold, which may never happen.

Callers that retry on -ERESTARTSYS allocate a new fence each time.
tegra20_channel_capture_frame() retries in a loop without delay, and
while the syncpoint does not move, for example with a camera that
delivers no frames, every round leaks one fence until the system runs
out of memory. Svyatoslav Ryhel reported this as an out-of-memory crash
in the VI capture thread; the allocations in his report come from
host1x_fence_create(), called by host1x_syncpt_wait() from
tegra20_chan_capture_kthread_start(). The DRM syncpoint wait IOCTLs end
up in host1x_syncpt_wait() as well, so a process that is signalled while
waiting leaks a fence the same way.

Cancel the fence whenever the wait did not succeed. host1x_fence_cancel()
is safe if the interrupt path has signalled the fence in the meantime,
as do_fence_timeout() then returns early.

The leak was found with the help of an LLM assistant reading the host1x
and dma-fence code against the call chain in the report.

Fixes: d5179020f5ce ("gpu: host1x: External timeout/cancellation for fences")
Cc: stable@vger.kernel.org
Reported-by: Svyatoslav Ryhel <clamor95@gmail.com>
Signed-off-by: Patrick Fischer <admin@tsv-stahl-riesa.de>
---
Svyatoslav reported the out-of-memory crash, and he confirmed off-list
that this patch stops the leak on his LG P895 (Tegra30). I left out a
Tested-by so that he can give it here.

I could not test this myself: the Tegra Note 7 I work on has no
working camera path in mainline yet. Build-tested for arm and arm64.
The DRM IOCTL case in the changelog comes from reading the code; I have
not tried it.

The retry loop in tegra20_channel_capture_frame() still spins without
delay as long as the wait keeps returning -ERESTARTSYS. With this patch
that costs CPU time instead of memory; how the VI driver should handle
an interrupted wait is a separate question.

Tool use (see Documentation/process/generated-content.rst): an LLM
assistant (Claude, in a chat) found the leak by reading
host1x_syncpt_wait() and the fence code against the call chain in the
OOM report. Claude Code then checked the finding against the code and
wrote the change, the changelog and this note from my notes and
instructions. I reviewed the change.
---
 drivers/gpu/host1x/syncpt.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/host1x/syncpt.c b/drivers/gpu/host1x/syncpt.c
index fe74ff6fc6f2..f9c871f218f3 100644
--- a/drivers/gpu/host1x/syncpt.c
+++ b/drivers/gpu/host1x/syncpt.c
@@ -247,7 +247,7 @@ int host1x_syncpt_wait(struct host1x_syncpt *sp, u32 thresh, long timeout,
 		return PTR_ERR(fence);
 
 	wait_err = dma_fence_wait_timeout(fence, true, timeout);
-	if (wait_err == 0)
+	if (wait_err <= 0)
 		host1x_fence_cancel(fence);
 	dma_fence_put(fence);
 

---
base-commit: 9d66f26fefacebfeed15de31c1123451a17ff119
change-id: 20261113-upstream-host1x-fence-cancel-0b32753150d6

Best regards,
--  
Patrick Fischer <admin@tsv-stahl-riesa.de>

