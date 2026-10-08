# Offline test (no Checkmk or 1Password needed): the stored password comes from the configured 1Password field, and
# an invalid identifier is rejected. Run: tofu test (from this directory)

mock_provider "checkmk" {}

mock_provider "onepassword" {
  mock_data "onepassword_item" {
    defaults = {
      section_map = {
        rustfs = {
          id       = "section-id"
          file_map = {}
          field_map = {
            SECRET_KEY = { id = "f1", type = "CONCEALED", value = "mock-secret-value" }
            ACCESS_KEY = { id = "f2", type = "CONCEALED", value = "mock-access-key" }
          }
        }
      }
    }
  }
}

variables {
  checkmk              = { url = "https://checkmk.example.com/prod", username = "terraform", secret = "automation-secret" }
  onepassword          = { service_account_token = "token" }
  onepassword_vault_id = "vault-id"
  item_title           = "checkmk-monitoring#dev"
  password_id          = "dev_checkmk_monitoring"
  title                = "dev-checkmk-monitoring"
}

run "stores_the_secret_field_from_1password" {
  command = plan

  assert {
    condition     = checkmk_password.this.password == "mock-secret-value"
    error_message = "The Password Store entry must carry the SECRET_KEY field of the 1Password item."
  }

  assert {
    condition     = checkmk_password.this.password_id == "dev_checkmk_monitoring"
    error_message = "The Password Store identifier must be the given password_id."
  }
}

run "other_field_can_be_selected" {
  command = plan

  variables {
    field_label = "ACCESS_KEY"
  }

  assert {
    condition     = checkmk_password.this.password == "mock-access-key"
    error_message = "field_label must select the field."
  }
}

run "identifier_with_hash_is_rejected" {
  command = plan

  variables {
    password_id = "checkmk-monitoring#dev"
  }

  expect_failures = [var.password_id]
}

run "identifier_starting_with_digit_is_rejected" {
  command = plan

  variables {
    password_id = "1dev"
  }

  expect_failures = [var.password_id]
}
