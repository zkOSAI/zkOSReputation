// zkOS Reputation Protocol Contract - Converted from Solidity to Rust (Anchor Framework)

use anchor_lang::prelude::*;
use anchor_lang::solana_program::clock;

// Constants
const MAX_ANSWERS: usize = 10;
const MAX_STRING_LENGTH: usize = 2000;

// Declare Program ID
declare_id!("zkOSReputation111111111111111111111111111111");

#[program]
pub mod zkOS_reputation {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, token_mint: Pubkey) -> Result<()> {
        let settings = &mut ctx.accounts.settings;
        settings.owner = *ctx.accounts.owner.key;
        settings.zkOS_token_mint = token_mint;
        settings.zkOS_per_question = 1_000_000_000_000_000_000; // 1e18
        settings.min_cap = 5;
        settings.max_cap = 500;
        settings.service_fee = 1;
        Ok(())
    }

    pub fn add_warranty(ctx: Context<AddWarranty>, amount: u64) -> Result<()> {
        let validator = &mut ctx.accounts.validator;
        validator.wallet = ctx.accounts.user.key();
        validator.warranty_amount += amount;
        ctx.accounts.statistics.total_zkOS_warranty += amount;
        Ok(())
    }

    pub fn set_question(
        ctx: Context<SetQuestion>,
        id: u64,
        question: String,
        answers: Vec<String>,
        correct_answer: String,
    ) -> Result<()> {
        require!(question.len() <= MAX_STRING_LENGTH, CustomError::StringTooLong);
        let q = &mut ctx.accounts.question;
        q.id = id;
        q.question = question;
        q.answers = answers;
        q.answer = correct_answer;
        Ok(())
    }

    // Other functions like create_new_reputation, reply, evaluate, claim_rewards, etc. would follow...
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(init, payer = owner, space = 8 + Settings::SIZE)]
    pub settings: Account<'info, Settings>,
    #[account(init, payer = owner, space = 8 + Statistics::SIZE)]
    pub statistics: Account<'info, Statistics>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[derive(Accounts)]
pub struct AddWarranty<'info> {
    #[account(mut)]
    pub validator: Account<'info, Validator>,
    #[account(mut)]
    pub statistics: Account<'info, Statistics>,
    pub user: Signer<'info>,
}

#[derive(Accounts)]
pub struct SetQuestion<'info> {
    #[account(init_if_needed, payer = owner, space = 8 + QuestionWithAnswer::SIZE, seeds = [b"question", &id.to_le_bytes()], bump)]
    pub question: Account<'info, QuestionWithAnswer>,
    #[account(mut)]
    pub owner: Signer<'info>,
    pub system_program: Program<'info, System>,
}

#[account]
pub struct Settings {
    pub owner: Pubkey,
    pub zkOS_token_mint: Pubkey,
    pub max_cap: u64,
    pub min_cap: u64,
    pub zkOS_per_question: u64,
    pub service_fee: u8,
}

impl Settings {
    const SIZE: usize = 32 + 32 + 8 + 8 + 8 + 1;
}

#[account]
pub struct Statistics {
    pub total_zkOS_burnt: u64,
    pub total_zkOS_fee: u64,
    pub total_zkOS_warranty: u64,
}

impl Statistics {
    const SIZE: usize = 8 * 3;
}

#[account]
pub struct Validator {
    pub wallet: Pubkey,
    pub amount: u64,
    pub warranty_amount: u64,
    pub locked_warranty_amount: u64,
    pub burnt_warranty: u64,
}

#[account]
pub struct QuestionWithAnswer {
    pub id: u64,
    pub question: String,
    pub answers: Vec<String>,
    pub answer: String,
}

impl QuestionWithAnswer {
    const SIZE: usize = 8 + (MAX_STRING_LENGTH * 3); // Rough estimate
}

#[error_code]
pub enum CustomError {
    #[msg("String input too long")]
    StringTooLong,
}
