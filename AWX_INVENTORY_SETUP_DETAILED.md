# 📦 AWX Minimal Inventory Setup - Detailed Step-by-Step Guide

## 🎯 Why Do We Need This?

Even though we're using **dynamic targeting** (entering server IP at runtime via Survey), AWX still requires:
1. An inventory to be selected in the job template
2. A localhost host for the first play (which adds the target server dynamically)

This is a **one-time setup** - you create it once and use it for all dynamic installations.

---

## 📋 Step-by-Step Instructions

### Step 1: Navigate to Inventories

1. **Login to AWX**: https://9.46.241.103
   - Username: `admin`
   - Password: `Finance@123456789`

2. **Click on** the left sidebar menu: **Resources**

3. **Click on**: **Inventories**

You should see a page showing existing inventories (if any).

---

### Step 2: Create New Inventory

1. **Click** the **Add** button (blue button with + icon in the top right)

2. **Select**: **Add inventory** (not "Add smart inventory")

3. **Fill in the form**:

   ```
   Name: Dynamic Execution Inventory
   ```
   *(Type exactly as shown, or use your own name)*

   ```
   Description: Minimal inventory for dynamic SSMS installation via Survey
   ```
   *(Optional but recommended)*

   ```
   Organization: Default
   ```
   *(Select from dropdown - should be "Default")*

4. **Leave other fields** as default:
   - Instance Groups: (leave empty)
   - Labels: (leave empty)
   - Variables: (leave empty for now)

5. **Click**: **Save** (green button at bottom)

**✅ Result**: You should see a success message and be taken to the inventory details page.

---

### Step 3: Add Localhost Host

Now we need to add a single host called "localhost" to this inventory.

1. **You should be on** the inventory details page for "Dynamic Execution Inventory"
   - If not, go to: Resources → Inventories → Click on "Dynamic Execution Inventory"

2. **Click on** the **Hosts** tab (at the top of the page)

3. **Click** the **Add** button (blue button with + icon)

4. **Fill in the host form**:

   ```
   Name: localhost
   ```
   *(Type exactly as shown - this is important)*

   ```
   Description: Local execution host for dynamic targeting
   ```
   *(Optional)*

5. **In the Variables section** (YAML format), enter:

   ```yaml
   ---
   ansible_connection: local
   ansible_python_interpreter: /usr/bin/python3
   ```

   **Important**: 
   - Make sure to include the `---` at the top
   - Use proper YAML indentation (no tabs, use spaces)
   - Copy exactly as shown above

6. **Click**: **Save** (green button at bottom)

**✅ Result**: You should see "localhost" appear in the hosts list.

---

### Step 4: Verify the Setup

1. **Go back to** the inventory: Resources → Inventories → Dynamic Execution Inventory

2. **Check the summary**:
   - **Hosts**: Should show `1`
   - **Groups**: Should show `0`

3. **Click on** the **Hosts** tab

4. **Verify** you see:
   - Host name: `localhost`
   - Status: Should have a green checkmark or be enabled

**✅ Your minimal inventory is now ready!**

---

## 🔍 What Each Part Does

### The Inventory
```
Name: Dynamic Execution Inventory
Purpose: Container for the localhost host
Usage: Selected in job template
```

### The Localhost Host
```
Name: localhost
Purpose: Runs the first play that adds target server dynamically
Variables:
  - ansible_connection: local (connects to AWX server itself)
  - ansible_python_interpreter: /usr/bin/python3 (uses Python 3)
```

---

## 📊 Visual Representation

```
┌─────────────────────────────────────────────────────────┐
│         Dynamic Execution Inventory                     │
│  (This is just a container - no real servers here)      │
│                                                          │
│  ┌────────────────────────────────────────────────┐    │
│  │  Host: localhost                               │    │
│  │  Connection: local                             │    │
│  │  Purpose: Runs first play to add target       │    │
│  └────────────────────────────────────────────────┘    │
│                                                          │
│  When job runs:                                         │
│  1. First play runs on localhost                        │
│  2. Localhost adds target server dynamically            │
│  3. Second play runs on target server                   │
│  4. SSMS gets installed on target server                │
└─────────────────────────────────────────────────────────┘
```

---

## 🎯 How It Works in the Playbook

The playbook has two plays:

### Play 1: Runs on localhost (AWX server)
```yaml
- name: Gather Dynamic Input for SSMS Installation
  hosts: localhost  # ← Uses the localhost we just created
  tasks:
    - name: Add target host to inventory dynamically
      add_host:
        name: "{{ survey_target_host }}"  # ← Server IP from survey
        groups: dynamic_windows_servers
```

### Play 2: Runs on target server (from survey)
```yaml
- name: Install MS SQL Server Management Studio on Windows
  hosts: dynamic_windows_servers  # ← The server we added dynamically
  tasks:
    - name: Install SSMS
      # ... installation tasks
```

---

## ❓ Common Questions

### Q1: Why can't I skip the inventory?
**A**: AWX requires every job template to have an inventory. Even for dynamic execution, we need a minimal inventory with localhost.

### Q2: Do I need to add my Windows servers to this inventory?
**A**: **NO!** That's the whole point of dynamic execution. You only add localhost. The Windows servers are added at runtime via the survey.

### Q3: Can I use an existing inventory?
**A**: Yes, if you have an existing inventory with a localhost host configured with `ansible_connection: local`, you can use that instead.

### Q4: What if I have multiple AWX projects?
**A**: You can reuse the same "Dynamic Execution Inventory" for all dynamic job templates. Create it once, use it everywhere.

### Q5: Can I name it something else?
**A**: Yes! You can name the inventory anything you want. Just remember to select it when creating the job template.

---

## ✅ Verification Checklist

After completing the steps, verify:

- [ ] Inventory "Dynamic Execution Inventory" exists
- [ ] Inventory shows 1 host
- [ ] Host "localhost" exists in the inventory
- [ ] Host variables include `ansible_connection: local`
- [ ] Host variables include `ansible_python_interpreter: /usr/bin/python3`
- [ ] No errors or warnings shown

---

## 🚀 Next Steps

Now that your inventory is ready:

1. ✅ **Inventory Created** ← You are here
2. ⏳ **Create Job Template** (next step)
3. ⏳ **Add Survey to Job Template**
4. ⏳ **Test the Installation**

Proceed to create the job template using this inventory!

---

## 🆘 Troubleshooting

### Issue: Can't find "Add" button
**Solution**: Make sure you're logged in as admin and have proper permissions.

### Issue: Variables section not accepting YAML
**Solution**: 
- Make sure to start with `---`
- Use spaces, not tabs
- Check YAML syntax at: https://www.yamllint.com/

### Issue: Inventory shows 0 hosts after adding
**Solution**: 
- Refresh the page
- Click on the Hosts tab to verify
- Check if the host was actually saved

### Issue: "localhost" already exists error
**Solution**: 
- You might have an existing localhost in another inventory
- Use a different name like "local-exec" or "awx-local"
- Update the playbook's first play to use the new name

---

## 📸 What You Should See

### After Creating Inventory:
```
┌─────────────────────────────────────────────────────────┐
│ Dynamic Execution Inventory                             │
│ ─────────────────────────────────────────────────────── │
│ Hosts: 1    Groups: 0    Sources: 0                     │
│                                                          │
│ [Details] [Access] [Hosts] [Groups] [Sources] [Jobs]    │
└─────────────────────────────────────────────────────────┘
```

### After Adding Localhost Host:
```
┌─────────────────────────────────────────────────────────┐
│ Hosts                                          [Add +]   │
│ ─────────────────────────────────────────────────────── │
│ ✓ localhost                                             │
│   Local execution host for dynamic targeting            │
└─────────────────────────────────────────────────────────┘
```

---

## 💡 Pro Tips

1. **Reusable**: Create this inventory once, use it for all dynamic playbooks
2. **Naming**: Use descriptive names so you remember what it's for
3. **Documentation**: Add good descriptions to help other team members
4. **Testing**: After creating, you can test it with a simple ping playbook

---

## 🎯 Summary

You've created a **minimal inventory** with just **localhost**. This is required by AWX but doesn't represent your actual Windows servers. The actual target servers will be added dynamically at runtime when you fill the survey form.

**Key Points**:
- ✅ Inventory name: Dynamic Execution Inventory
- ✅ Contains: 1 host (localhost)
- ✅ Purpose: Required by AWX for dynamic execution
- ✅ Your Windows servers: NOT in this inventory (added dynamically)

---

**Ready for next step**: Create Job Template with Survey!

---

*Made with ❤️ by Bob*