(* Messages to be wrapped in a box and displayed to the user.
 *
 * $Id: msg.sml,v 1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Msg =
struct
   (* Handling photo collections. *)
   val invalid_collection =
      "<p>" ^
      "<b>Invalid collection!</b><br />" ^
      "You have tried to access a collection that does not exist.  This " ^
      "is probably because of an invalid URL.  If the problem persists, " ^
      "please report it.</p>\n"

   val new_col_insn =
      "<p>" ^
      "This page allows you to create a new collection as a child of " ^
      "your current collection.  Collections may hold photos or other " ^
      "collections, allowing you to create filesystem-like layouts.  The " ^
      "collection name is a descriptive name that means something " ^
      "to people, while the collection directory must be one word. " ^
      "We use the name to display to people and we use the directory " ^
      "for paths and for actually storing the pictures.</p>\n"

   val col_must_be_logged_in =
      "<p>" ^
      "<b>You aren't logged in!</b><br />" ^
      "You must be logged in before you can make a new collection.  If " ^
      "you already have an account, click on the login link in the top " ^
      "bar.  If you do not already have an account, you may create one " ^
      "using the account creation link in the top bar.</p>\n"

   val no_new_col_perms =
      "<p>" ^
      "<b>You don't have permission!</b><br />" ^
      "You do not have the permission to make a new collection in this " ^
      "location.  The most likely cause of this is that you have tried " ^
      "to make a collection in one you don't own.  Or, you are simply " ^
      "not allowed to make collections in general.  If you'd like to " ^
      "be able to add your own collections, please contact the browser " ^
      "administrator.</p>\n"

   val bad_new_collection =
      "<p>" ^
      "<b>Problem with the new collection form.</b><br />" ^
      "Make sure you have filled in all the fields on the form and that " ^
      "a collection does not already exist with the name you are trying " ^
      "to use.  Please go back to the new collection page and try " ^
      "again.</p>\n"

   val collection_created =
      "<p>" ^
      "<b>Collection created!</b><br />" ^
      "The new collection has successfully been created.  You may now " ^
      "navigate to your new collection and add photos to it.</p>\n"

   (* Making new accounts. *)
   val new_acct_insn =
      "<p>" ^
      "This page allows you to create a new photo browser account.  " ^
      "An account allows you to post comments on pictures and possibly " ^
      "even make your own galleries.  It may let you do other things in " ^
      "the future.  All fields on this form are required, and will never " ^
      "be shared with anyone else.  Please make sure you have reviewed " ^
      "the copyright and terms of service page, linked at the bottom of " ^
      "every page.</p>\n"

   val bad_new_acct =
      "<p>" ^
      "<b>Problem with the account form.</b><br />" ^
      "Please make sure you have filled in all the fields on the form and " ^
      "that the two password fields match.  Please go back to the new " ^
      "account page and try again.</p>\n"

   val acct_created =
      "<p>" ^
      "<b>Account created!</b><br />" ^
      "The new account has successfully been created.  Please go to the " ^
      "login page linked to from the top of this screen to login to " ^
      "your new account.</p>\n"

   (* Logging in/out. *)
   val bad_name_password =
      "<p>" ^
      "<b>Incorrect name or password!</b><br />" ^
      "Logging in failed, because you entered an incorrect name or " ^
      "password.  Please try again.</p>\n"
      
   val logged_in =
      "<p>" ^
      "<b>Login successful!</b><br />" ^
      "You are now logged in to the photo browser.</p>\n"

   val logged_out =
      "<p>" ^
      "<b>Logout successful!</b><br />" ^
      "You have been logged out from the photo browser, and any cookies " ^
      "placed on your system have been removed.</p>\n"

   val not_logged_in =
      "<p>" ^
      "<b>You are not logged in.</b><br />" ^
      "You must be logged in before you can log out.</p>\n"
end
