using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    public class Realtor
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int realtor_id { get; set; }

        [Required(ErrorMessage = "ФИО обязательно для заполнения")]
        [MaxLength(100, ErrorMessage = "ФИО не должно превышать 100 символов")]
        [Display(Name = "ФИО")]
        public string full_name { get; set; } = string.Empty;

        [Required(ErrorMessage = "Телефон обязателен для заполнения")]
        [MaxLength(20, ErrorMessage = "Телефон не должен превышать 20 символов")]
        [Phone(ErrorMessage = "Неверный формат телефона")]
        [Display(Name = "Телефон")]
        public string phone_number { get; set; } = string.Empty;

        [Required(ErrorMessage = "Email обязателен для заполнения")]
        [MaxLength(100, ErrorMessage = "Email не должен превышать 100 символов")]
        [EmailAddress(ErrorMessage = "Неверный формат email")]
        [Display(Name = "Email")]
        public string email { get; set; } = string.Empty;

        [Required(ErrorMessage = "Дата найма обязательна для заполнения")]
        [DataType(DataType.Date)]
        [Display(Name = "Дата найма")]
        [DisplayFormat(DataFormatString = "{0:yyyy-MM-dd}", ApplyFormatInEditMode = true)]
        public DateTime hire_date { get; set; }

        [Required(ErrorMessage = "Комиссия обязательна для заполнения")]
        [Range(0, 100, ErrorMessage = "Комиссия должна быть от 0 до 100%")]
        [Display(Name = "Комиссия (%)")]
        public decimal commission_rate { get; set; }

        // Внешний ключ для User
        [Display(Name = "ID пользователя")]
        public int? user_id { get; set; }

        // Навигационное свойство для User
        [ForeignKey("user_id")]
        public virtual User? User { get; set; }

        // --- ИСПРАВЛЕНИЕ: Добавлено навигационное свойство для связи с бронированиями ---
        public virtual ICollection<PropertyReservation> Reservations { get; set; } = new List<PropertyReservation>();

        [NotMapped]
        [Display(Name = "Статус")]
        public string Status
        {
            get
            {
                var experience = DateTime.Now - hire_date;
                return experience.TotalDays >= 365 ? "Активен" : "Стажёр";
            }
        }

        [NotMapped]
        [Display(Name = "Стаж работы")]
        public string Experience
        {
            get
            {
                var experience = DateTime.Now - hire_date;
                var years = experience.Days / 365;
                var months = (experience.Days % 365) / 30;
                return $"{years} год., {months} мес.";
            }
        }

        public bool Validate(out List<string> errors)
        {
            errors = new List<string>();
            if (string.IsNullOrWhiteSpace(full_name)) errors.Add("ФИО обязательно для заполнения");
            if (full_name?.Length > 100) errors.Add("ФИО не должно превышать 100 символов");
            if (string.IsNullOrWhiteSpace(phone_number)) errors.Add("Телефон обязателен для заполнения");
            if (string.IsNullOrWhiteSpace(email)) errors.Add("Email обязателен для заполнения");
            if (!new EmailAddressAttribute().IsValid(email)) errors.Add("Неверный формат email");
            if (hire_date > DateTime.Now) errors.Add("Дата найма не может быть в будущем");
            if (commission_rate < 0 || commission_rate > 100) errors.Add("Комиссия должна быть от 0 до 100%");
            return errors.Count == 0;
        }
    }
}