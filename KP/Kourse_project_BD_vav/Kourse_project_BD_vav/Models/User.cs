using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    public class User
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int user_id { get; set; }

        [Required]
        [MaxLength(50)]
        public string username { get; set; } = string.Empty;

        [Required]
        [MaxLength(255)]
        public string password_hash { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string email { get; set; } = string.Empty;

        [Required]
        [MaxLength(100)]
        public string full_name { get; set; } = string.Empty;

        [Required]
        [MaxLength(20)]
        public string role { get; set; } = "Client";

        public DateTime created_at { get; set; }

        public int? client_id { get; set; }

        public int? realtor_id { get; set; }
    }

    public class LoginModel
    {
        [Required]
        public string Username { get; set; } = string.Empty;

        [Required]
        [DataType(DataType.Password)]
        public string Password { get; set; } = string.Empty;

        public bool RememberMe { get; set; }
        public string Email { get; set; } = string.Empty;
    }

    public class RegisterModel
    {
        [Required(ErrorMessage = "Поле ФИО обязательно для заполнения")]
        [Display(Name = "ФИО")]
        [MaxLength(100)]
        public string FullName { get; set; } = string.Empty;

        [Required(ErrorMessage = "Поле Имя пользователя обязательно для заполнения")]
        [Display(Name = "Имя пользователя")]
        [MaxLength(50)]
        public string Username { get; set; } = string.Empty;

        [Required(ErrorMessage = "Поле Email обязательно для заполнения")]
        [EmailAddress(ErrorMessage = "Email имеет неверный формат")]
        [Display(Name = "Email")]
        [MaxLength(100)]
        public string Email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Поле Пароль обязательно для заполнения")]
        [DataType(DataType.Password)]
        [MinLength(6, ErrorMessage = "Пароль должен содержать минимум 6 символов")]
        [Display(Name = "Пароль")]
        public string Password { get; set; } = string.Empty;

        [Required(ErrorMessage = "Поле Подтверждение пароля обязательно для заполнения")]
        [DataType(DataType.Password)]
        [Compare("Password", ErrorMessage = "Пароли не совпадают")]
        [Display(Name = "Подтверждение пароля")]
        public string ConfirmPassword { get; set; } = string.Empty;

        [Required(ErrorMessage = "Поле Роль обязательно для заполнения")]
        [Display(Name = "Роль")]
        public string Role { get; set; } = "Client";
    }
}