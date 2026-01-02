-- =============================================
-- QUIZ SYSTEM MIGRATION
-- Created: 2026-01-02
-- Purpose: Daily financial quizzes for Quick Earnings feature
-- Points: 15pts per quiz completion
-- =============================================

-- =============================================
-- TABLE: quizzes
-- Stores daily quiz metadata
-- =============================================
CREATE TABLE quizzes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    category TEXT,
    active_date DATE NOT NULL UNIQUE,
    difficulty TEXT CHECK (difficulty IN ('easy', 'medium', 'hard')),
    estimated_time_seconds INT DEFAULT 60,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- =============================================
-- TABLE: quiz_questions
-- Stores questions for each quiz (3 per quiz)
-- =============================================
CREATE TABLE quiz_questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID REFERENCES quizzes(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    question_order INT NOT NULL,
    option_a TEXT NOT NULL,
    option_b TEXT NOT NULL,
    option_c TEXT NOT NULL,
    option_d TEXT NOT NULL,
    correct_answer TEXT CHECK (correct_answer IN ('a', 'b', 'c', 'd')),
    explanation TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(quiz_id, question_order)
);

-- =============================================
-- TABLE: quiz_attempts
-- Stores user quiz attempts and scores
-- =============================================
CREATE TABLE quiz_attempts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    quiz_id UUID REFERENCES quizzes(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    score INT DEFAULT 0,
    total_questions INT DEFAULT 3,
    is_completed BOOLEAN DEFAULT false,
    answers JSONB,
    completed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(quiz_id, user_id)
);

-- =============================================
-- INDEXES: Optimize lookups
-- =============================================
CREATE INDEX idx_quizzes_active_date ON quizzes(active_date);
CREATE INDEX idx_quiz_questions_quiz_id ON quiz_questions(quiz_id);
CREATE INDEX idx_quiz_attempts_user_id ON quiz_attempts(user_id);
CREATE INDEX idx_quiz_attempts_quiz_id ON quiz_attempts(quiz_id);

-- =============================================
-- RLS POLICIES
-- =============================================
ALTER TABLE quizzes ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_attempts ENABLE ROW LEVEL SECURITY;

-- Anyone can view quizzes
CREATE POLICY "Anyone can view quizzes"
ON quizzes FOR SELECT
USING (true);

-- Anyone can view quiz questions
CREATE POLICY "Anyone can view questions"
ON quiz_questions FOR SELECT
USING (true);

-- Users can view their own attempts
CREATE POLICY "Users view own attempts"
ON quiz_attempts FOR SELECT
USING (auth.uid() = user_id);

-- Users can insert their own attempts
CREATE POLICY "Users insert own attempts"
ON quiz_attempts FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Users can update their own attempts
CREATE POLICY "Users update own attempts"
ON quiz_attempts FOR UPDATE
USING (auth.uid() = user_id);

-- =============================================
-- SEED DATA: 30 Quizzes with 90 Questions
-- =============================================

-- Quiz 1: Budgeting Basics (2026-01-01)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Budgeting Basics', 'Test your knowledge of fundamental budgeting principles', 'budgeting', '2026-01-01', 'easy', 45);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-01'), 'What is the 50/30/20 budgeting rule?', 1, '50% needs, 30% wants, 20% savings', '50% savings, 30% needs, 20% wants', '50% wants, 30% savings, 20% needs', '50% rent, 30% food, 20% fun', 'a', 'The 50/30/20 rule suggests allocating 50% to needs, 30% to wants, and 20% to savings and debt repayment.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-01'), 'How many months of expenses should an emergency fund cover?', 2, '1-2 months', '3-6 months', '12 months', '24 months', 'b', 'Financial experts recommend saving 3-6 months of living expenses in an emergency fund.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-01'), 'What''s a "zero-based budget"?', 3, 'Spending nothing each month', 'Every dollar has a job', 'Starting with zero savings', 'Having no debt', 'b', 'Zero-based budgeting means every dollar you earn is assigned a specific purpose, leaving zero unallocated.');

-- Quiz 2: Credit Score Secrets (2026-01-02)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Credit Score Secrets', 'Learn what affects your credit score', 'credit', '2026-01-02', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-02'), 'What''s the most important factor in your credit score?', 1, 'Payment history', 'Credit utilization', 'Length of credit history', 'New credit inquiries', 'a', 'Payment history accounts for about 35% of your FICO score, making it the most important factor.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-02'), 'What credit utilization ratio should you aim for?', 2, 'Under 90%', 'Under 50%', 'Under 30%', 'Under 10%', 'c', 'Experts recommend keeping credit utilization below 30% of your available credit limit.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-02'), 'How long do hard inquiries stay on your credit report?', 3, '6 months', '1 year', '2 years', '7 years', 'c', 'Hard inquiries remain on your credit report for 2 years but typically only impact your score for the first year.');

-- Quiz 3: Saving Strategies (2026-01-03)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Saving Strategies', 'Discover smart ways to save money', 'saving', '2026-01-03', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-03'), 'What''s "paying yourself first"?', 1, 'Getting a paycheck before bills', 'Saving before spending', 'Treating yourself monthly', 'Keeping cash on hand', 'b', '"Pay yourself first" means automatically transferring money to savings before you spend on anything else.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-03'), 'What''s a high-yield savings account?', 2, 'An account for wealthy people', 'A savings account with higher interest rates', 'A retirement account', 'A checking account', 'b', 'High-yield savings accounts offer interest rates significantly higher than traditional savings accounts.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-03'), 'What''s the "latte factor"?', 3, 'Buying expensive coffee daily', 'Small daily expenses that add up', 'Coffee shop investments', 'Caffeine addiction costs', 'b', 'The "latte factor" refers to small, regular expenses (like daily coffee) that accumulate significantly over time.');

-- Quiz 4: Investment 101 (2026-01-04)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Investment 101', 'Basic investing concepts everyone should know', 'investing', '2026-01-04', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-04'), 'What does "diversification" mean?', 1, 'Investing all money in one stock', 'Spreading investments across different assets', 'Only buying tech stocks', 'Avoiding the stock market', 'b', 'Diversification means spreading your investments across various assets to reduce risk.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-04'), 'What''s a 401(k)?', 2, 'A type of savings account', 'An employer-sponsored retirement plan', 'A government bond', 'A bank loan', 'b', 'A 401(k) is an employer-sponsored retirement savings plan that offers tax advantages.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-04'), 'What''s the benefit of compound interest?', 3, 'Paying less in taxes', 'Earning interest on your interest', 'Getting higher salary', 'Reducing debt faster', 'b', 'Compound interest means you earn interest on both your principal and previously earned interest, accelerating growth.');

-- Quiz 5: Debt Management (2026-01-05)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Debt Management', 'Smart strategies for handling debt', 'debt', '2026-01-05', 'medium', 55);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-05'), 'What''s the "debt snowball" method?', 1, 'Paying highest interest first', 'Paying smallest debt first', 'Making minimum payments only', 'Consolidating all debts', 'b', 'The debt snowball method focuses on paying off the smallest debt first for psychological wins.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-05'), 'What''s the "debt avalanche" method?', 2, 'Paying smallest debt first', 'Paying highest interest rate first', 'Ignoring debts until later', 'Paying newest debt first', 'b', 'The debt avalanche method prioritizes debts with the highest interest rates to save money.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-05'), 'What''s a balance transfer?', 3, 'Moving money between accounts', 'Transferring debt to a lower-interest card', 'Paying off a loan early', 'Closing a credit card', 'b', 'A balance transfer moves high-interest credit card debt to a card with a lower interest rate.');

-- Quiz 6: Smart Shopping (2026-01-06)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Smart Shopping', 'How to shop wisely and save money', 'shopping', '2026-01-06', 'easy', 45);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-06'), 'What''s the 24-hour rule for purchases?', 1, 'Shop only during sales', 'Wait 24 hours before buying', 'Return items within 24 hours', 'Shop for 24 items max', 'b', 'The 24-hour rule suggests waiting a day before making non-essential purchases to avoid impulse buying.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-06'), 'What''s "unit pricing"?', 2, 'Price per item in bulk', 'Cost per standard unit (oz, lb)', 'Total checkout price', 'Discount percentage', 'b', 'Unit pricing shows the cost per standard unit (like per ounce) to help compare products fairly.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-06'), 'When are grocery stores usually least crowded?', 3, 'Weekend mornings', 'Weekday evenings', 'Weekday early mornings', 'Sunday afternoons', 'c', 'Grocery stores are typically least crowded on weekday early mornings, making shopping faster.');

-- Quiz 7: Tax Basics (2026-01-07)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Tax Basics', 'Understanding fundamental tax concepts', 'taxes', '2026-01-07', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-07'), 'What''s a tax deduction?', 1, 'Money the IRS owes you', 'Reduces your taxable income', 'A type of penalty', 'Your total tax bill', 'b', 'A tax deduction reduces your taxable income, lowering the amount of tax you owe.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-07'), 'What''s a tax credit?', 2, 'Increases your refund amount', 'Reduces tax owed dollar-for-dollar', 'A loan from the government', 'Interest on unpaid taxes', 'b', 'A tax credit directly reduces the amount of tax you owe, dollar-for-dollar.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-07'), 'What''s the standard deduction?', 3, 'A fixed amount that reduces taxable income', 'Tax on your salary', 'A penalty for late filing', 'Your total tax refund', 'a', 'The standard deduction is a fixed dollar amount that reduces your taxable income.');

-- Quiz 8: Banking Basics (2026-01-08)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Banking Basics', 'Essential banking knowledge', 'banking', '2026-01-08', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-08'), 'What''s an overdraft fee?', 1, 'Charge for using ATM', 'Charge for spending more than account balance', 'Monthly account fee', 'Interest on savings', 'b', 'An overdraft fee is charged when you spend more money than you have in your account.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-08'), 'What''s APY?', 2, 'Annual Payment Yield', 'Annual Percentage Yield', 'Average Payment Year', 'Annual Premium Yield', 'b', 'APY (Annual Percentage Yield) shows the real rate of return on savings including compound interest.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-08'), 'What''s a routing number?', 3, 'Your account password', 'Bank''s identification number', 'Your account balance', 'Credit card number', 'b', 'A routing number is a 9-digit code that identifies your bank for transfers and deposits.');

-- Quiz 9: Retirement Planning (2026-01-09)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Retirement Planning', 'Start planning for your future today', 'retirement', '2026-01-09', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-09'), 'What''s the recommended retirement savings rate?', 1, '5% of income', '10-15% of income', '25% of income', '50% of income', 'b', 'Financial experts recommend saving 10-15% of your gross income for retirement.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-09'), 'What''s an IRA?', 2, 'Individual Retirement Account', 'Insurance Retirement Account', 'Investment Risk Account', 'Income Reduction Account', 'a', 'An IRA (Individual Retirement Account) is a tax-advantaged account for retirement savings.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-09'), 'What age can you withdraw from 401(k) without penalty?', 3, '55', '59½', '62', '65', 'b', 'You can withdraw from a 401(k) without early withdrawal penalty starting at age 59½.');

-- Quiz 10: Financial Goals (2026-01-10)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Financial Goals', 'Setting and achieving money goals', 'planning', '2026-01-10', 'easy', 45);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-10'), 'What does SMART goals stand for?', 1, 'Simple, Meaningful, Achievable, Realistic, Timely', 'Specific, Measurable, Achievable, Relevant, Time-bound', 'Smart, Money-focused, Aggressive, Rewarding, Trackable', 'Save, Monitor, Achieve, Record, Track', 'b', 'SMART goals are Specific, Measurable, Achievable, Relevant, and Time-bound.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-10'), 'What''s a short-term financial goal?', 2, 'Retirement savings', 'House down payment', 'Emergency fund of $1000', 'College fund for kids', 'c', 'Short-term goals are typically achievable within 1 year, like building a small emergency fund.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-10'), 'How often should you review your financial goals?', 3, 'Once a year', 'Every 3-6 months', 'Once every 5 years', 'Never, set and forget', 'b', 'Reviewing financial goals every 3-6 months helps you stay on track and make adjustments.');

-- Quiz 11: Insurance Essentials (2026-01-11)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Insurance Essentials', 'Understanding insurance basics', 'insurance', '2026-01-11', 'medium', 55);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-11'), 'What''s a deductible?', 1, 'Monthly insurance payment', 'Amount you pay before insurance kicks in', 'Your total coverage limit', 'Insurance company profit', 'b', 'A deductible is the amount you must pay out-of-pocket before your insurance coverage begins.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-11'), 'What''s a premium?', 2, 'High-quality insurance', 'Regular payment for coverage', 'Insurance claim amount', 'Deductible amount', 'b', 'A premium is the regular payment (usually monthly) you make to maintain insurance coverage.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-11'), 'What does term life insurance cover?', 3, 'Specific time period', 'Your entire life', 'Medical expenses only', 'Car accidents', 'a', 'Term life insurance provides coverage for a specific time period (like 10, 20, or 30 years).');

-- Quiz 12: Money Mindset (2026-01-12)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Money Mindset', 'Your psychology around money', 'psychology', '2026-01-12', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-12'), 'What''s "lifestyle inflation"?', 1, 'Rising cost of living', 'Spending more as income increases', 'Credit card interest', 'Investment growth', 'b', 'Lifestyle inflation is when spending increases proportionally with income, preventing wealth building.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-12'), 'What''s a "scarcity mindset"?', 2, 'Being frugal with money', 'Believing there''s never enough', 'Saving aggressively', 'Avoiding debt', 'b', 'A scarcity mindset is the belief that there will never be enough resources, leading to poor financial decisions.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-12'), 'What''s "delayed gratification"?', 3, 'Late payments on bills', 'Choosing long-term rewards over immediate pleasure', 'Procrastinating on savings', 'Paying bills late', 'b', 'Delayed gratification is the ability to resist immediate rewards for greater long-term benefits.');

-- Quiz 13: Credit Cards (2026-01-13)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Credit Cards', 'Using credit cards wisely', 'credit', '2026-01-13', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-13'), 'What''s APR on a credit card?', 1, 'Annual Point Rewards', 'Annual Percentage Rate (interest)', 'Automatic Payment Rate', 'Available Purchase Rate', 'b', 'APR is the Annual Percentage Rate - the interest rate charged on balances carried month-to-month.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-13'), 'What''s a grace period?', 2, 'Time to pay without interest', 'Late payment forgiveness', 'Credit limit increase time', 'Reward points expiration', 'a', 'A grace period is the time between purchase and due date where no interest is charged if you pay in full.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-13'), 'What''s the minimum payment?', 3, 'Best amount to pay monthly', 'Smallest required payment', 'Maximum you can pay', 'Your total balance', 'b', 'The minimum payment is the smallest amount you must pay to avoid late fees, but interest still accrues.');

-- Quiz 14: Side Hustles (2026-01-14)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Side Hustles', 'Earning extra income', 'income', '2026-01-14', 'easy', 45);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-14'), 'What''s the gig economy?', 1, 'Concert ticket sales', 'Freelance and contract work', 'Tech industry jobs', 'Stock market trading', 'b', 'The gig economy consists of freelance, contract, and temporary positions rather than traditional employment.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-14'), 'Do you pay taxes on side hustle income?', 2, 'No, it''s extra money', 'Yes, all income is taxable', 'Only if over $10,000', 'Only for full-time work', 'b', 'All income, including side hustles, is taxable and must be reported to the IRS.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-14'), 'What''s passive income?', 3, 'Not working at all', 'Money earned with minimal ongoing effort', 'Government assistance', 'Inheritance money', 'b', 'Passive income is money earned with minimal active effort, like rental income or dividends.');

-- Quiz 15: Frugal Living (2026-01-15)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Frugal Living', 'Living well while spending less', 'lifestyle', '2026-01-15', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-15'), 'What''s the difference between cheap and frugal?', 1, 'They''re the same thing', 'Frugal prioritizes value, cheap prioritizes low cost', 'Cheap is better than frugal', 'Frugal means no spending', 'b', 'Being frugal means seeking value and quality for money spent, while being cheap focuses only on lowest cost.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-15'), 'What''s meal prepping?', 2, 'Eating at restaurants', 'Preparing meals in advance', 'Ordering takeout weekly', 'Skipping meals to save', 'b', 'Meal prepping involves preparing multiple meals in advance to save time and money.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-15'), 'What''s a "no-spend challenge"?', 3, 'Never buying anything again', 'Avoiding non-essential spending for a set time', 'Only buying on sale', 'Using cash only', 'b', 'A no-spend challenge means avoiding all non-essential purchases for a set period like a week or month.');

-- Quiz 16: Student Loans (2026-01-16)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Student Loans', 'Managing education debt', 'debt', '2026-01-16', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-16'), 'What''s the difference between subsidized and unsubsidized loans?', 1, 'Interest rates differ', 'Government pays interest on subsidized while in school', 'Subsidized are private loans', 'No difference', 'b', 'For subsidized loans, the government pays interest while you''re in school. Unsubsidized loans accrue interest immediately.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-16'), 'What''s income-driven repayment?', 2, 'Paying based on salary', 'Fixed monthly payment', 'Paying only interest', 'Deferring all payments', 'a', 'Income-driven repayment plans set your monthly payment based on your income and family size.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-16'), 'What''s loan forgiveness?', 3, 'Late payment penalty removal', 'Cancellation of remaining debt after conditions met', 'Lower interest rate', 'Extended repayment term', 'b', 'Loan forgiveness cancels the remaining balance of your loan after you meet specific requirements.');

-- Quiz 17: Real Estate (2026-01-17)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Real Estate', 'Home buying and renting basics', 'housing', '2026-01-17', 'medium', 55);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-17'), 'What''s a down payment?', 1, 'Monthly mortgage payment', 'Upfront payment for home purchase', 'Property tax', 'Moving costs', 'b', 'A down payment is the initial upfront payment made when buying a home, typically 3-20% of purchase price.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-17'), 'What''s PMI?', 2, 'Property Management Insurance', 'Private Mortgage Insurance', 'Public Market Interest', 'Personal Money Investment', 'b', 'PMI (Private Mortgage Insurance) is required when you put down less than 20% on a home.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-17'), 'What''s the 28/36 rule for home buying?', 3, 'Age requirements', 'Housing costs shouldn''t exceed 28% income, total debt 36%', 'Interest rate limits', 'Down payment percentages', 'b', 'The 28/36 rule states housing costs should be no more than 28% of gross income, and total debt no more than 36%.');

-- Quiz 18: Stock Market (2026-01-18)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Stock Market', 'Basics of stock investing', 'investing', '2026-01-18', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-18'), 'What''s a stock?', 1, 'A loan to a company', 'Ownership share in a company', 'Company''s savings account', 'Government bond', 'b', 'A stock represents partial ownership (a share) in a company.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-18'), 'What''s a dividend?', 2, 'Stock price increase', 'Company profit paid to shareholders', 'Trading fee', 'Stock split', 'b', 'A dividend is a portion of company profits paid out to shareholders, usually quarterly.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-18'), 'What''s an index fund?', 3, 'Single company stock', 'Fund tracking market index like S&P 500', 'Savings account', 'Cryptocurrency', 'b', 'An index fund is a type of mutual fund designed to match the performance of a market index like the S&P 500.');

-- Quiz 19: Financial Scams (2026-01-19)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Financial Scams', 'Protecting yourself from fraud', 'security', '2026-01-19', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-19'), 'What''s phishing?', 1, 'Fishing for deals', 'Fraudulent attempt to obtain sensitive info', 'Legitimate bank communication', 'Investment strategy', 'b', 'Phishing is when scammers impersonate legitimate organizations to steal personal information via email or text.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-19'), 'Red flag for a scam?', 2, 'Professional email address', 'Pressure to act immediately', 'Slow response time', 'Detailed information', 'b', 'Scammers create urgency and pressure you to act quickly before you can think critically.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-19'), 'What should you NEVER share?', 3, 'Your first name', 'Your Social Security Number with strangers', 'Your email address', 'Your phone number', 'b', 'Never share your SSN, passwords, or banking info with unsolicited callers or emails.');

-- Quiz 20: Bill Negotiation (2026-01-20)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Bill Negotiation', 'How to lower your monthly bills', 'saving', '2026-01-20', 'easy', 45);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-20'), 'Can you negotiate cable/internet bills?', 1, 'No, prices are fixed', 'Yes, providers often have retention offers', 'Only for new customers', 'Only if you threaten to cancel', 'b', 'Most cable and internet providers have special retention departments that can offer discounts to keep customers.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-20'), 'Best time to negotiate bills?', 2, 'When you''re happy with service', 'When contract is ending', 'After missing payment', 'Never', 'b', 'The best leverage is when your contract is ending and you can threaten to switch providers.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-20'), 'What''s medical bill negotiation?', 3, 'Illegal practice', 'Requesting payment plan or reduction', 'Ignoring medical bills', 'Using insurance incorrectly', 'b', 'You can often negotiate medical bills by requesting payment plans, discounts for paying in full, or challenging incorrect charges.');

-- Quiz 21: Emergency Funds (2026-01-21)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Emergency Funds', 'Building your financial safety net', 'saving', '2026-01-21', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-21'), 'What qualifies as an emergency?', 1, 'New phone', 'Unexpected medical bill', 'Holiday shopping', 'Concert tickets', 'b', 'True emergencies are unexpected necessary expenses like medical bills, car repairs, or job loss.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-21'), 'Where should you keep emergency funds?', 2, 'Stock market', 'High-yield savings account', 'Under mattress', 'Cryptocurrency', 'b', 'Emergency funds should be in easily accessible, safe accounts like high-yield savings with FDIC insurance.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-21'), 'First emergency fund goal?', 3, '$100', '$1,000', '$10,000', '$50,000', 'b', 'Financial experts recommend starting with $1,000 as your initial emergency fund goal.');

-- Quiz 22: Financial Apps (2026-01-22)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Financial Apps', 'Using technology to manage money', 'technology', '2026-01-22', 'easy', 45);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-22'), 'What do budgeting apps do?', 1, 'Automatically pay bills', 'Track spending and categorize expenses', 'Invest your money', 'File your taxes', 'b', 'Budgeting apps connect to your accounts to automatically track and categorize your spending.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-22'), 'What''s two-factor authentication?', 2, 'Using two apps', 'Extra security layer beyond password', 'Paying twice for security', 'Having two bank accounts', 'b', 'Two-factor authentication requires a second verification (like a text code) beyond your password for security.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-22'), 'What''s a robo-advisor?', 3, 'Robot bank teller', 'Automated investment management service', 'Budgeting app', 'Tax software', 'b', 'A robo-advisor is an automated platform that manages your investments based on your goals and risk tolerance.');

-- Quiz 23: Car Finances (2026-01-23)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Car Finances', 'Smart car buying and ownership', 'spending', '2026-01-23', 'medium', 55);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-23'), 'What''s better financially?', 1, 'Always lease', 'Always buy', 'Depends on situation', 'Rent cars as needed', 'c', 'Whether to buy or lease depends on factors like how long you keep cars, annual mileage, and financial situation.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-23'), 'What''s the 20/4/10 rule for car buying?', 2, '20 month loan, 4% interest, 10% down', '20% down, 4-year loan, payment <10% income', '20 year warranty, 4 owners max, 10% trade-in', '20 mpg, 4 doors, $10k max', 'b', 'The 20/4/10 rule: 20% down payment, 4-year loan maximum, total expenses under 10% of gross income.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-23'), 'What hurts car resale value most?', 3, 'Regular maintenance', 'High mileage and poor condition', 'One owner', 'Complete service records', 'b', 'High mileage, accidents, poor maintenance, and cosmetic damage significantly decrease resale value.');

-- Quiz 24: Grocery Savings (2026-01-24)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Grocery Savings', 'Cutting your food costs', 'shopping', '2026-01-24', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-24'), 'What saves most money at grocery stores?', 1, 'Shopping hungry', 'Meal planning and lists', 'Buying everything organic', 'Shopping daily', 'b', 'Meal planning and shopping with a list prevents impulse purchases and food waste.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-24'), 'When do stores mark down perishables?', 2, 'Opening time', 'Mid-afternoon', 'Evening (near closing)', 'Never', 'c', 'Stores often mark down perishables in the evening to sell them before closing.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-24'), 'What''s the cheapest protein per pound?', 3, 'Steak', 'Chicken breast', 'Beans and lentils', 'Salmon', 'c', 'Beans and lentils provide excellent protein at the lowest cost per pound.');

-- Quiz 25: Salary Negotiation (2026-01-25)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Salary Negotiation', 'Getting paid what you''re worth', 'income', '2026-01-25', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-25'), 'When should you negotiate salary?', 1, 'During first interview', 'After receiving job offer', 'Never, take what''s offered', 'During performance review only', 'b', 'The best time to negotiate is after receiving an offer when you have the most leverage.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-25'), 'What''s the first rule of salary negotiation?', 2, 'Accept immediately', 'Let them make first offer', 'Demand highest salary', 'Share your current salary', 'b', 'Try to let the employer make the first offer to understand their range before committing to a number.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-25'), 'Besides salary, what else can you negotiate?', 3, 'Nothing else matters', 'PTO, remote work, signing bonus, benefits', 'Only title', 'Only start date', 'b', 'You can often negotiate vacation time, remote work options, signing bonuses, professional development, and more.');

-- Quiz 26: Cryptocurrency (2026-01-26)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Cryptocurrency', 'Digital currency basics', 'investing', '2026-01-26', 'hard', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-26'), 'What''s blockchain?', 1, 'Type of cryptocurrency', 'Digital ledger technology', 'Bitcoin wallet', 'Mining equipment', 'b', 'Blockchain is a distributed digital ledger that records transactions across many computers securely.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-26'), 'What''s crypto volatility?', 2, 'Stable prices', 'Rapid, significant price fluctuations', 'Government regulation', 'Mining difficulty', 'b', 'Cryptocurrency is known for extreme price volatility - rapid and significant price swings up or down.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-26'), 'Recommended crypto allocation for beginners?', 3, '100% of portfolio', '50% of portfolio', '5-10% of portfolio', 'All emergency fund', 'c', 'Financial advisors suggest limiting crypto to 5-10% of your portfolio due to high risk and volatility.');

-- Quiz 27: Financial Independence (2026-01-27)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Financial Independence', 'The path to FIRE', 'planning', '2026-01-27', 'medium', 55);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-27'), 'What does FIRE stand for?', 1, 'Financial Income Retirement Early', 'Financial Independence, Retire Early', 'Fixed Income Real Estate', 'Free Income Retirement Earnings', 'b', 'FIRE stands for Financial Independence, Retire Early - a movement focused on saving aggressively to retire young.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-27'), 'What''s the 4% rule?', 2, 'Save 4% of income', 'Withdraw 4% of portfolio annually in retirement', 'Invest 4% in stocks', '4% interest rate minimum', 'b', 'The 4% rule suggests you can safely withdraw 4% of your retirement portfolio annually without running out of money.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-27'), 'What''s your FI number?', 3, 'Age you retire', '25x annual expenses', 'Your salary', 'Years until retirement', 'b', 'Your FI (Financial Independence) number is typically 25x your annual expenses - the amount needed to retire.');

-- Quiz 28: Side Gig Taxes (2026-01-28)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Side Gig Taxes', 'Tax implications of extra income', 'taxes', '2026-01-28', 'medium', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-28'), 'What''s self-employment tax?', 1, 'Extra tax penalty', 'Social Security and Medicare tax for self-employed', 'Federal income tax', 'State sales tax', 'b', 'Self-employment tax covers Social Security and Medicare contributions (15.3%) that employers normally pay half of.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-28'), 'When do you owe quarterly taxes?', 2, 'Never', 'If you expect to owe $1,000+ in taxes', 'Only if full-time self-employed', 'Only for corporations', 'b', 'If you expect to owe $1,000 or more in taxes, you should make quarterly estimated tax payments.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-28'), 'What business expenses are deductible?', 3, 'Personal groceries', 'Ordinary and necessary business expenses', 'All purchases', 'Nothing is deductible', 'b', 'You can deduct ordinary and necessary business expenses like supplies, software, and workspace costs.');

-- Quiz 29: Economic Indicators (2026-01-29)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Economic Indicators', 'Understanding the economy', 'economics', '2026-01-29', 'hard', 60);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-29'), 'What''s inflation?', 1, 'Prices going down', 'General increase in prices over time', 'Stock market crash', 'Interest rates', 'b', 'Inflation is the rate at which the general level of prices for goods and services rises, eroding purchasing power.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-29'), 'What does the Fed do?', 2, 'Print money randomly', 'Sets monetary policy and interest rates', 'Collects taxes', 'Regulates stocks', 'b', 'The Federal Reserve (Fed) sets monetary policy including interest rates to manage economic growth and inflation.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-29'), 'What''s a recession?', 3, 'One month of decline', 'Two consecutive quarters of economic decline', 'Stock market correction', 'High unemployment only', 'b', 'A recession is technically defined as two consecutive quarters of negative GDP growth.');

-- Quiz 30: Money Myths (2026-01-30)
INSERT INTO quizzes (title, description, category, active_date, difficulty, estimated_time_seconds)
VALUES ('Money Myths', 'Debunking common financial misconceptions', 'education', '2026-01-30', 'easy', 50);

INSERT INTO quiz_questions (quiz_id, question_text, question_order, option_a, option_b, option_c, option_d, correct_answer, explanation)
VALUES
((SELECT id FROM quizzes WHERE active_date = '2026-01-30'), 'Myth: You need money to make money. True?', 1, 'True, always', 'False - you can start small', 'True for investing only', 'True for everyone', 'b', 'FALSE - You can start building wealth with small amounts through consistent saving and low-cost index funds.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-30'), 'Myth: Renting is throwing money away. True?', 2, 'Always true', 'False - depends on situation', 'True if rent is high', 'True after 5 years', 'b', 'FALSE - Renting can be smart if it''s cheaper than owning, you value flexibility, or you''re not ready to buy.'),
((SELECT id FROM quizzes WHERE active_date = '2026-01-30'), 'Myth: You need to be debt-free to build wealth. True?', 3, 'Always true', 'False - strategic debt can help', 'True for mortgages', 'True for everyone', 'b', 'FALSE - Low-interest debt like mortgages can be strategic while you invest in higher-return assets.');

-- =============================================
-- VERIFICATION QUERIES
-- =============================================
-- SELECT COUNT(*) FROM quizzes; -- Should be 30
-- SELECT COUNT(*) FROM quiz_questions; -- Should be 90
-- SELECT * FROM quizzes ORDER BY active_date;
-- SELECT q.*, qq.question_text FROM quizzes q
-- JOIN quiz_questions qq ON q.id = qq.quiz_id
-- WHERE q.active_date = CURRENT_DATE
-- ORDER BY qq.question_order;
