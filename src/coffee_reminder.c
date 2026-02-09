// SPDX-License-Identifier: GPL-2.0
#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/kthread.h>
#include <linux/delay.h>
#include <linux/timekeeping.h>
#include <linux/sysfs.h>
#include <linux/kobject.h>
#include <linux/input.h>
#include <linux/errno.h>

MODULE_AUTHOR("Coffee Reminder");
MODULE_DESCRIPTION("Kernel module that beeps PC speaker at configured times");
MODULE_LICENSE("GPL");

static struct task_struct *worker_thread;
static struct kobject *coffee_kobj;

// Store schedule in HH:MM comma-separated, e.g., "09:00,12:00,15:00"
#define MAX_SCHED_LEN 256
static char sched_str[MAX_SCHED_LEN] = "09:00,12:00,15:00"; // renamed from 'schedule' to avoid clash with kernel symbol
static int beep_ms = 1000; // duration of beep in ms
static int enabled = 1;

static bool time_matches(const struct timespec64 *ts)
{
    struct tm tm;
    time64_to_tm(ts->tv_sec, 0, &tm);
    // Build current HH:MM
    char cur_time[6]; // renamed from 'current' to avoid macro clash
    snprintf(cur_time, sizeof(cur_time), "%02d:%02d", tm.tm_hour, tm.tm_min);

    // Linear scan schedule string for match at minute precision
    const char *p = sched_str;
    while (*p) {
        // skip separators
        while (*p == ' ' || *p == ',') p++;
        if (!*p) break;
        // compare 5 chars HH:MM
        if (strlen(p) >= 5 && strncmp(p, cur_time, 5) == 0)
            return true;
        // advance to next comma
        while (*p && *p != ',') p++;
    }
    return false;
}

static void pcspkr_beep(int msecs)
{
    // Use input subsystem bell if available
#ifdef CONFIG_INPUT_PCSPKR
    input_event(NULL, EV_SND, SND_BELL, 1);
    msleep(msecs);
    input_event(NULL, EV_SND, SND_BELL, 0);
#else
    // Fallback: print to kernel log
    pr_info("coffee_reminder: Beep! (pcspkr not available)\n");
    msleep(msecs);
#endif
}

static int coffee_worker(void *data)
{
    pr_info("coffee_reminder: worker started\n");
    while (!kthread_should_stop()) {
        if (enabled) {
            struct timespec64 ts;
            ktime_get_real_ts64(&ts);
            if (time_matches(&ts)) {
                pr_info("coffee_reminder: time matched, beeping for %d ms\n", beep_ms);
                pcspkr_beep(beep_ms);
                // Sleep until next minute to avoid multiple beeps within same minute
                msleep(60000);
                continue;
            }
        }
        // Sleep a short interval and recheck
        msleep(1000);
    }
    pr_info("coffee_reminder: worker stopped\n");
    return 0;
}

// Sysfs attributes
static ssize_t schedule_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return scnprintf(buf, PAGE_SIZE, "%s\n", sched_str);
}

static ssize_t schedule_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
    size_t n = min(count, (size_t)(MAX_SCHED_LEN - 1));
    memcpy(sched_str, buf, n);
    // strip trailing newline
    if (n > 0 && sched_str[n-1] == '\n') n--;
    sched_str[n] = '\0';
    pr_info("coffee_reminder: schedule set to '%s'\n", sched_str);
    return count;
}

static struct kobj_attribute schedule_attr = __ATTR(schedule, 0664, schedule_show, schedule_store);

static ssize_t enabled_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return scnprintf(buf, PAGE_SIZE, "%d\n", enabled);
}

static ssize_t enabled_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
    int val;
    if (kstrtoint(buf, 10, &val) == 0) {
        enabled = !!val;
        pr_info("coffee_reminder: enabled=%d\n", enabled);
    }
    return count;
}

static struct kobj_attribute enabled_attr = __ATTR(enabled, 0664, enabled_show, enabled_store);

static ssize_t beep_ms_show(struct kobject *kobj, struct kobj_attribute *attr, char *buf)
{
    return scnprintf(buf, PAGE_SIZE, "%d\n", beep_ms);
}

static ssize_t beep_ms_store(struct kobject *kobj, struct kobj_attribute *attr, const char *buf, size_t count)
{
    int val;
    if (kstrtoint(buf, 10, &val) == 0 && val > 0 && val <= 10000) {
        beep_ms = val;
        pr_info("coffee_reminder: beep_ms=%d\n", beep_ms);
    }
    return count;
}

static struct kobj_attribute beep_ms_attr = __ATTR(beep_ms, 0664, beep_ms_show, beep_ms_store);

static struct attribute *attrs[] = {
    &schedule_attr.attr,
    &enabled_attr.attr,
    &beep_ms_attr.attr,
    NULL,
};

static const struct attribute_group attr_group = {
    .attrs = attrs,
};

static int __init coffee_init(void)
{
    int ret;
    coffee_kobj = kobject_create_and_add("coffee_reminder", kernel_kobj);
    if (!coffee_kobj)
        return -ENOMEM;

    ret = sysfs_create_group(coffee_kobj, &attr_group);
    if (ret) {
        kobject_put(coffee_kobj);
        return ret;
    }

    worker_thread = kthread_run(coffee_worker, NULL, "coffee_reminder");
    if (IS_ERR(worker_thread)) {
        ret = PTR_ERR(worker_thread);
        sysfs_remove_group(coffee_kobj, &attr_group);
        kobject_put(coffee_kobj);
        return ret;
    }

    pr_info("coffee_reminder: loaded\n");
    return 0;
}

static void __exit coffee_exit(void)
{
    if (worker_thread)
        kthread_stop(worker_thread);
    if (coffee_kobj) {
        sysfs_remove_group(coffee_kobj, &attr_group);
        kobject_put(coffee_kobj);
    }
    pr_info("coffee_reminder: unloaded\n");
}

module_init(coffee_init);
module_exit(coffee_exit);
