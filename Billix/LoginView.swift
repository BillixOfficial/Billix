import SwiftUI

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isSecured = true
    @State private var showAlert = false
    @State private var rememberMe = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.billixLightBeige,
                        Color.billixYellowGold.opacity(0.3)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    hideKeyboard()
                }

                // Decorative background circles
                Circle()
                    .fill(Color.billixMutedPurple.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)

                Circle()
                    .fill(Color.billixSoftGreen.opacity(0.1))
                    .frame(width: 200, height: 200)
                    .position(x: geometry.size.width * 0.2, y: geometry.size.height * 0.8)

                VStack(spacing: 30) {
                    Spacer()

                    // Logo/Brand Section
                    VStack(spacing: 10) {
                        // Billix Logo
                        Image("billix_logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.billixYellowGold.opacity(0.3),
                                                Color.billixMutedPurple.opacity(0.3)
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            )
                            .shadow(color: Color.billixDarkGray.opacity(0.2), radius: 8, x: 0, y: 4)

                        Text("Billix")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.billixDarkGray)

                        Text("Manage your finances smartly")
                            .font(.subheadline)
                            .foregroundColor(.billixMutedPurple)
                    }

                    Spacer()

                    // Login Form
                    VStack(spacing: 20) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.headline)
                                .foregroundColor(.billixDarkGray)

                            TextField("Enter your email", text: $email)
                                .textFieldStyle(BillixTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }

                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.headline)
                                .foregroundColor(.billixDarkGray)

                            HStack {
                                if isSecured {
                                    SecureField("Enter your password", text: $password)
                                        .textContentType(.password)
                                } else {
                                    TextField("Enter your password", text: $password)
                                        .textContentType(.password)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }

                                Button(action: {
                                    isSecured.toggle()
                                }) {
                                    Image(systemName: isSecured ? "eye.slash" : "eye")
                                        .foregroundColor(.billixMutedPurple)
                                }
                            }
                            .textFieldStyle(BillixTextFieldStyle())
                        }

                        // Remember Me & Forgot Password
                        HStack {
                            Button(action: {
                                rememberMe.toggle()
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                        .foregroundColor(.billixMutedPurple)
                                    Text("Remember me")
                                        .font(.footnote)
                                        .foregroundColor(.billixDarkGray)
                                }
                            }

                            Spacer()

                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .font(.footnote)
                            .foregroundColor(.billixMutedPurple)
                        }

                        // Login Button
                        Button(action: {
                            handleLogin()
                        }) {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.billixOliveGreen,
                                            Color.billixSoftGreen
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                        }

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.billixMutedPurple.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .font(.footnote)
                                .foregroundColor(.billixMutedPurple)
                                .padding(.horizontal)
                            Rectangle()
                                .fill(Color.billixMutedPurple.opacity(0.3))
                                .frame(height: 1)
                        }

                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.footnote)
                                .foregroundColor(.billixDarkGray)

                            Button("Sign Up") {
                                // Handle sign up
                            }
                            .font(.footnote)
                            .foregroundColor(.billixMutedPurple)
                        }
                    }
                    .padding(.horizontal, 30)

                    Spacer()
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text("Login"),
                message: Text("Login functionality not implemented yet"),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func handleLogin() {
        // Dismiss keyboard
        hideKeyboard()

        // Basic validation
        guard !email.isEmpty, !password.isEmpty else {
            showAlert = true
            return
        }

        // TODO: Implement actual login logic
        print("Login attempted with email: \(email)")
        showAlert = true
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

struct BillixTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.8))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.billixMutedPurple.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
}
