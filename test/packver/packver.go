package packver

func Version() string {
	// This file's purpose is to be pinned to a specific tag (by one of the
	// tests) and if that happens correctly, the below line will be instead
	// "v0.2.3", which it's obviously not if you're reading this comment.
	return "this version should not be returned"
}
