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
                // Background gradient - matching logo colors
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.billixCreamBeige,
                        Color.billixGoldenAmber.opacity(0.2)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                .onTapGesture {
                    // Dismiss keyboard when tapping background
                    hideKeyboard()
                }

                // Decorative background circles - matching logo
                Circle()
                    .fill(Color.billixPurple.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .position(x: geometry.size.width * 0.8, y: geometry.size.height * 0.2)

                Circle()
                    .fill(Color.billixDarkTeal.opacity(0.12))
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
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.billixGoldenAmber,
                                                Color.billixNavyBlue
                                            ]),
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 4
                                    )
                            )
                            .shadow(color: Color.billixDarkTeal.opacity(0.3), radius: 12, x: 0, y: 6)

                        Text("Billix")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.billixNavyBlue, Color.billixDarkTeal],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Save Smart, Spend Wise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.billixPurple)
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
                                        .foregroundColor(.billixPurple)
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
                                        .foregroundColor(.billixPurple)
                                    Text("Remember me")
                                        .font(.footnote)
                                        .foregroundColor(.billixNavyBlue)
                                }
                            }

                            Spacer()

                            Button("Forgot Password?") {
                                // Handle forgot password
                            }
                            .font(.footnote)
                            .foregroundColor(.billixDarkTeal)
                        }

                        // Login Button
                        Button(action: {
                            handleLogin()
                        }) {
                            Text("Sign In")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 55)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.billixMoneyGreen,
                                            Color.billixDarkTeal
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(12)
                                .shadow(color: Color.billixDarkTeal.opacity(0.4), radius: 8, x: 0, y: 4)
                        }

                        // Divider
                        HStack {
                            Rectangle()
                                .fill(Color.billixPurple.opacity(0.3))
                                .frame(height: 1)
                            Text("or")
                                .font(.footnote)
                                .foregroundColor(.billixPurple)
                                .padding(.horizontal)
                            Rectangle()
                                .fill(Color.billixPurple.opacity(0.3))
                                .frame(height: 1)
                        }

                        // Sign Up Link
                        HStack {
                            Text("Don't have an account?")
                                .font(.footnote)
                                .foregroundColor(.billixNavyBlue)

                            Button("Sign Up") {
                                // Handle sign up
                            }
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.billixPurple)
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
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.9))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.billixPurple.opacity(0.4), lineWidth: 1.5)
            )
            .shadow(color: Color.billixPurple.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    LoginView()
}
